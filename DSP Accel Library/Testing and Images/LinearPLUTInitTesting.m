% Define mask inputs
clear; close all;
W_bits = 32;                % fixed-point word size
isSigned = true;            % defines if table input is signed
F_bits = 28;                % fixed-point fractional size
errorParam = .1;            % allowed absolute error
ERR_DIAG = true;            % flag to show table init
IGOTTHIS = false;           % flag to manually define address width
ADDR_W_MANUAL = 4;          % manually defined address width
tableFnParam = "sin(xIn)";  % desired function

%% LINEAR PLUT INIT SCRIPT

% Copyright 2020 Flat Earth Inc
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
% INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
% PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
% FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
% E. Bailey Galacci
% Flat Earth Inc
% 985 Technology Blvd
% Bozeman, MT 59718
% support@flatearthinc.com

% things to display: table size, input bounds, funtion represented, max error
% things to figure out: N_bits, Min_val, X_in table, Y_out table, error
% RAM_SIZE, table size 

if(IGOTTHIS)
    N_bits = ADDR_W_MANUAL;
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
        xIn = -2^(W_bits-1-F_bits) : 2^(W_bits-F_bits-N_bits) : 2^(W_bits-1-F_bits) - 2^(W_bits-F_bits-N_bits);
    else
        xIn = 0 : 2^(W_bits-F_bits-N_bits) : 2^(W_bits-F_bits) - 2^(W_bits-F_bits-N_bits);
    end

    % use function to define output. note: function must contain input xIn
    % within the string to work properly, and the only output of the function
    % must be Y_out.
    tableInit = eval(tableFnParam);

    RAM_SIZE = N_bits;
    figure(2); plot(xIn,tableInit, 'k*'); title('Table Initialized Function');
    maxVal = xIn(end);
    minVal = xIn(1);
    %set_param(gcb,'MaskDisplay',"disp(sprintf('Programmable Look-up Table\nMemory Used = %d samples and coeffs\nClock Rate Needed = %d Hz', FIR_Uprate*2, Max_Rate)); port_label('input',1,'data'); port_label('input',2,'valid'); port_label('input',3,'Wr_Data'); port_label('input',4,'Wr_Addr'); port_label('input',5,'Wr_En'); port_label('output',1,'data'); port_label('output',2,'valid'); port_label('output',3,'RW_Dout');")

    %%%%%%%%%% check and identify error %%%%%%%%%%%
    % Make some values for an "ideal" lookup table with lin spaced points
    if(isSigned)
        xTest = -2^(W_bits-1-F_bits) : 2^(W_bits-F_bits-N_bits-2) : 2^(W_bits-1-F_bits) - 2^(W_bits-F_bits-N_bits);
    else
        xTest = 0 : 2^(W_bits-F_bits-N_bits-2) : 2^(W_bits-F_bits) - 2^(W_bits-F_bits-N_bits);
    end
    xTemp = xIn;
    xIn = xTest;
    % identify the values of the function at xTest
    yTest = eval(tableFnParam);

    % Return table input set to xIn (already have xTemp)
    xIn = xTemp;

    % Find lookup addresses for each point in xTest
    addrTest = zeros(1,length(xTest));
    for it = 1:length(xTest)
        addrTest(it) = 2^RAM_SIZE;
        while(xTest(it) < xIn(addrTest(it)) && addrTest(it) ~= 1)
            addrTest(it) = addrTest(it) - 1;
        end
        if(addrTest(it)==0) %% sanity check for out of bounds results
            addrTest(it) = 1;
        end
    end
    
    yLow = tableInit(addrTest);

    % Check for any possible out of bounds errors (handled similarly in
    % hardware)
    addrTest(addrTest == 2^RAM_SIZE) = 2^RAM_SIZE -1;

    
    % absolute error: abs(obt-exp)
    errorFloor = abs(yTest-yLow);
    NAN_CLEANUP = isnan(errorFloor);
    errorFloor(NAN_CLEANUP) = 0;
    %errorInter = (Y_out_Ideal-y_inter)./Y_out_Ideal;
    %maxFloorErr(ix) = 100*max(abs(errorFloor(ix, 2870:9839)));
    %maxInterErr(ix) = 100*max(abs(errorInter(ix, 2870:9839)));
    maxErr = max(abs(errorFloor));
    
    %check while loop condition
    if(IGOTTHIS) 
        repeatFlag = false;
    end
    
    if(maxErr <= errorParam || N_bits > W_bits)
        repeatFlag = false;
    else
%        if(ERR_DIAG)
%            f = msgbox(sprintf('Err = %.2d, N_bits = %d', maxErr, N_bits),'Configuring PLUT','replace');
%        end
        
        % make table larger to increase accuracy
        if(maxErr > errorParam)
            N_bits = N_bits+1;
        end
    end
end%end while loop

% printout graph of table values and error test
% prinout graph of table values and error test
if(ERR_DIAG)
    figure(1); 
    f = msgbox(sprintf('Err = +/- %.2d, Ram Size = %d bits  (%d by %d)', maxErr, 2^RAM_SIZE*W_bits, 2^RAM_SIZE, W_bits),'PLUT INIT','replace');
    subplot(2,1,1); plot(xTest,yLow, xTest,yTest,xIn,tableInit,'k*'); title('Output Values over Input Range'); xlabel('Inputs'); ylabel('Outputs'); legend('Table Results','Ideal','Table Points');
    subplot(2,1,2); plot(xTest, errorFloor); title('Error of Output over Input Range'); xlabel('Inputs'); ylabel('Absolute Error');
end

% things to display: table size, floor input?, max input, accuracy
if(isSigned) % setup for 2's compliment
    tableInit = [tableInit(2^(N_bits-1)+1:end) , tableInit(1:2^(N_bits-1))];
else
    tableInit = tableInit;
end

% this line uncommented in the mask
% set_param(gcb,'MaskDisplay',"disp(sprintf(['Programmable Look-Up Table\nMemory Used = %d bits \n' tableFnParam ': %d <= x <= %d \n Maximum Error: %.2d'], 2^RAM_SIZE*W_bits, minVal, maxVal, maxErr)); port_label('input',1,'Data_In'); port_label('input',2,'Table_Wr_Data'); port_label('input',3,'Table_Wr_Addr'); port_label('input',4,'Table_Wr_En'); port_label('output',1,'Data_Out'); port_label('output',2,'Table_RW_Dout');")

