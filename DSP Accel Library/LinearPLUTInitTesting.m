%% Linear Addressing Init Script Testing
% Define mask inputs
clear; close all;
W_bits = 32;
isSigned = true;
F_bits = 28;
N_bits = 5;
error_cap_tab = .1;
ERR_DIAG = true;
igotthis = false;
addr_w_manual = 4;
TableFn = "X_in./5";

% things to display: table size, floor input?, max input, accuracy
% things to figure out: M_bits, N_bits, Min_val, X_in table, Y_out table,
% max_error, ram_size, table_size 

if(igotthis)
    N_bits = addr_w_manual;
else
    N_bits = 4;
    % N_bits will likely need to be updated later, until table is large enough to meet
    % accuracy standards defined by user
end;

repeatFlag = true;
while(repeatFlag)
    % Define a 2^N point log2 spaced range of inputs, from 2^(d-(2^N_bits -1)) to almost 2^(d+1), 
    % this effectively covers the user defined input range, down to a floor
    % value.
    % Signed vs Unsigned: If signed, treat word size as 1 smaller for max and
    % min inputs
    % Signed: 
    % smallest table input: -2^(W-1-F), 2's compliment, "[1, zeros(1,N-1)]"
    % step size: 2^(W-F-N)
    % largest table input: 2^(W-1-F) - 2^(W-F-N), smallest number but positive
    % and minus 1 step size, "[0, ones(1,N-1)]"
    % Unsigned: 
    % smallest table input: 0
    % step size: 2^(W-F-N)
    % largest table input: 2^(W-1-F) - 2^(W-F-N), smallest number but positive
    % and minus 1 step size, "[ones(1,N)]"
    if(isSigned)
        X_in = -2^(W_bits-1-F_bits) : 2^(W_bits-F_bits-N_bits) : 2^(W_bits-1-F_bits) - 2^(W_bits-F_bits-N_bits);
    else
        X_in = 0 : 2^(W_bits-F_bits-N_bits) : 2^(W_bits-F_bits) - 2^(W_bits-F_bits-N_bits);
    end

    % use function to define output. note: function must contain input X_in
    % within the string to work properly, and the only output of the function
    % must be Y_out.
    Y_out = eval(TableFn);

    ram_size = N_bits;
    Table_Init = Y_out;
    figure(2); plot(X_in,Y_out, 'k*'); title('Table Initialized Function');
    max_val = X_in(end);
    min_val = X_in(1);
    %set_param(gcb,'MaskDisplay',"disp(sprintf('Programmable Look-up Table\nMemory Used = %d samples and coeffs\nClock Rate Needed = %d Hz', FIR_Uprate*2, Max_Rate)); port_label('input',1,'data'); port_label('input',2,'valid'); port_label('input',3,'Wr_Data'); port_label('input',4,'Wr_Addr'); port_label('input',5,'Wr_En'); port_label('output',1,'data'); port_label('output',2,'valid'); port_label('output',3,'RW_Dout');")

    %%%%%%%%%% check and identify error %%%%%%%%%%%
    % Make some values for an "ideal" lookup table with lin spaced points
    if(isSigned)
        X_in_Ideal = -2^(W_bits-1-F_bits) : 2^(W_bits-F_bits-N_bits-2) : 2^(W_bits-1-F_bits) - 2^(W_bits-F_bits-N_bits);
    else
        X_in_Ideal = 0 : 2^(W_bits-F_bits-N_bits-2) : 2^(W_bits-F_bits) - 2^(W_bits-F_bits-N_bits);
    end
    X_temp = X_in;
    X_in = X_in_Ideal;
    % identify the values of the function at X_in_Ideal
    Y_out_Ideal = eval(TableFn);

    % Get values for lookup table (already have X_in)
    X_in = X_temp;

    % Find lookup addresses for each point in X_in_Ideal
    x_addr = zeros(1,length(X_in_Ideal));
    for it = 1:length(X_in_Ideal)
        x_addr(it) = 2^ram_size;
        X_Shift = X_in_Ideal(it);
        while(X_Shift < X_in(x_addr(it)) && x_addr(it) ~= 1)
            x_addr(it) = x_addr(it) - 1;
        end
        if(x_addr(it)==0)
            x_addr(it) = 1;
        end
    end
    
    y_floor = Y_out(x_addr);

    % Check for any possible out of bounds errors (handled similarly in
    % hardware)
    % x_addr(x_addr == 2^ram_size) = 2^ram_size -1;

    
    % absolute error: abs(obt-exp)
    errorFloor = abs(Y_out_Ideal-y_floor);
    NAN_CLEANUP = isnan(errorFloor);
    errorFloor(NAN_CLEANUP) = 0;
    %errorInter = (Y_out_Ideal-y_inter)./Y_out_Ideal;
    %maxFloorErr(ix) = 100*max(abs(errorFloor(ix, 2870:9839)));
    %maxInterErr(ix) = 100*max(abs(errorInter(ix, 2870:9839)));
    maxErr = max(abs(errorFloor));
    
    %check while loop condition
    if(igotthis) 
        repeatFlag = false;
        if(ERR_DIAG)
            figure(1); 
            subplot(2,1,1); plot(X_in_Ideal,y_floor, X_in_Ideal,Y_out_Ideal,X_in,Y_out,'k*'); title('Output Values over Input Range'); xlabel('Inputs'); ylabel('Outputs'); legend('Output','Ideal','Table Points');
            subplot(2,1,2); plot(X_in_Ideal,errorFloor); title('Error of Output over Input Range'); xlabel('Inputs'); ylabel('Absolute Error');
        end
        break;
    end
    
    if(maxErr <= error_cap_tab || N_bits > W_bits)
        repeatFlag = false;
        if(ERR_DIAG)
            figure(1); 
            subplot(2,1,1); plot(X_in_Ideal,y_floor, X_in_Ideal,Y_out_Ideal,X_in,Y_out,'k*'); title('Output Values over Input Range'); xlabel('Inputs'); ylabel('Outputs'); legend('Output','Ideal','Table Points');
            subplot(2,1,2); plot(X_in_Ideal,errorFloor); title('Error of Output over Input Range'); xlabel('Inputs'); ylabel('Absolute Error');
        end
    else
        if(ERR_DIAG)
            f = msgbox(sprintf('Err = %.2d, N_bits = %d', maxErr, N_bits),'Configuring PLUT','replace');
        end
        if(maxErr > 8*error_cap_tab)
            N_bits = N_bits+3;
        elseif(maxErr > 4*error_cap_tab)
            N_bits = N_bits+2;
        else
            N_bits = N_bits+1;
        end
    end
end%end while loop

%maxFloorErrTot = max(maxFloorErr);
%maxInterErrTot = max(maxInterErr);
%% things to display: table size, floor input?, max input, accuracy
if(isSigned) % setup for 2's compliment
    Table_Init = [Y_out(2^(N_bits-1)+1:end) , Y_out(1:2^(N_bits-1))];
else
    Table_Init = Y_out;
end

%set_param(gcb,'MaskDisplay',"disp(sprintf('Programmable Look-Up Table\nMemory Used = %d fixed point numbers\nInput Bounds: %.2d <= x <= %.2d\n Maximum Error: %.2d', 2^ram_size, min_val, max_val, maxErr)); port_label('input',1,'Data_In'); port_label('input',2,'Table_Wr_Data'); port_label('input',3,'Table_Wr_Addr'); port_label('input',4,'Table_Wr_En'); port_label('output',1,'Data_Out'); port_label('output',2,'Table_RW_Dout');")

