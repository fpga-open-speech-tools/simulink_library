%% TESTING OF PLUT INIT SCRIPTS
%
% This script is a copy of code used in the Programmable Look-Up Table's
% init script in the DSP_FPGA_Accelerated_Toolbox.

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

clear; close all;
tableFnParam = "log(xIn)";
maxInput = 1;
floorParam = 2^-12;
errorParam = 0.001;
ERR_DIAG = true;
nBitsParam = 4;
mBitsParam = 5;
IGOTTHIS = false;
W_bits = 32;
F_bits = 28;

% things to display: table size, floor input?, max input, accuracy
% things to figure out: M_bits, N_bits, Min_val, X_in table, Y_out table,
% max_error, ram_size, table_size 

binaryOffset = ceil(log2(maxInput)); % used for binary tricks, as well as identifying input range
if(IGOTTHIS)
    N_bits = nBitsParam;
    M_bits = mBitsParam;
else
    N_bits = ceil(log2(binaryOffset-log2(floorParam)+1));
    % M_bits needs to be defined later, as it must be just enough to meet
    % accuracy standards defined by user, with linear interpolation
    M_bits = 1; %this will be updated later as needed
end

repeatFlag = true;
while(repeatFlag)
    % Define a N point log2 spaced range of inputs, from 2^(d-(2^N_bits -1)) to almost 2^(d+1), 
    % this effectively covers the user defined input range, down to a floor
    % value.
    xIn = zeros(1, 2^(M_bits+N_bits));
    addr = 1;
    for NShifts = 2^N_bits-1:-1:0
        for M = 0:2^M_bits - 1
            xIn(addr) = 2^(binaryOffset-NShifts) + M*2^(binaryOffset-NShifts-M_bits);
            addr = addr+1;
        end
    end

    % use function to define output. note: function must contain input X_in
    % within the string to work properly, and the only output of the function
    % must be the table values.
    tableInit = eval(tableFnParam);

    RAM_SIZE = N_bits+M_bits;
    maxVal = 2^binaryOffset+ (2^M_bits -1)*2^(binaryOffset-M_bits);
    minVal = 2^(binaryOffset-(2^N_bits-1));
    %set_param(gcb,'MaskDisplay',"disp(sprintf('Programmable Look-up Table\nMemory Used = %d samples and coeffs\nClock Rate Needed = %d Hz', FIR_Uprate*2, Max_Rate)); port_label('input',1,'data'); port_label('input',2,'valid'); port_label('input',3,'Wr_Data'); port_label('input',4,'Wr_Addr'); port_label('input',5,'Wr_En'); port_label('output',1,'data'); port_label('output',2,'valid'); port_label('output',3,'RW_Dout');")

    %%%%%%%%%% check and identify error %%%%%%%%%%%
    % Define a set of test cases for the lookup table with log spaced points
    xTest = logspace(log10(minVal), log10(maxVal), 2^(RAM_SIZE+2));
    xTemp = xIn;
    xIn = xTest;
    % identify the values of the function at xTest
    yTest = eval(tableFnParam);

    % move lookup table values back to xIn
    xIn = xTemp;

    % Find lookup addresses for each point in xTest
    addrTest = zeros(1,length(xTest));
    for it = 1:length(xTest)
        addrTest(it) = 2^RAM_SIZE;
        while(xTest(it) < xIn(addrTest(it)) && addrTest(it) ~= 1)
            addrTest(it) = addrTest(it) - 1;
        end
        if(addrTest(it)==0)
            addrTest(it) = 1;
        end
    end

    % Check for any possible out of bounds errors (handled similarly in
    % hardware)
    addrTest(addrTest == 2^RAM_SIZE) = 2^RAM_SIZE -1;

    % Get values for linear interpolation of X_in_Ideal
    xLow  = xIn(addrTest);
    xHigh = xIn(addrTest+1);


    yLow  = tableInit(addrTest);
    yHigh = tableInit(addrTest+1);
    slope  = (yHigh-yLow) ./ (xHigh - xLow);
    yInter = slope.*(xTest-xLow)+yLow;
    % percent error: obt-exp / exp
    %errorFloor = (Y_out_Ideal-y_low)./Y_out_Ideal;
    errorInter = (yTest-yInter)./yTest;
    %maxFloorErr(ix) = 100*max(abs(errorFloor(ix, 2870:9839)));
    %maxInterErr(ix) = 100*max(abs(errorInter(ix, 2870:9839)));
    maxErr = max(abs(errorInter));
    %check while loop condition
    if(IGOTTHIS) 
        repeatFlag = false;
    else
        if(maxErr <= errorParam)
            repeatFlag = false;
            if(ERR_DIAG)
                figure(1); 
                subplot(2,1,1); semilogx(xTest,yInter, xTest,yTest,xIn,tableInit,'k*'); title('Output Values over Input Range'); xlabel('Inputs'); ylabel('Outputs'); legend('Interpolated','Ideal','Table Points');
                subplot(2,1,2); semilogx(xTest,100*errorInter); title('Error of Output over Input Range'); xlabel('Inputs'); ylabel('Percent Error');
            end
        else
            if(ERR_DIAG)
                f = msgbox(sprintf('Err = %.2d, M_bits = %d', maxErr, M_bits),'Configuring PLUT','replace');
            end
            if(maxErr > 8*errorParam)
                M_bits = M_bits+3;
            elseif(maxErr > 4*errorParam)
                M_bits = M_bits+2;
            else
                M_bits = M_bits+1;
            end
        end
    end
end%end while loop

% Some testing variables. Uncomment if desired.
%maxFloorErrTot = max(maxFloorErr);
%maxInterErrTot = max(maxInterErr);
% things to display: table size, floor input?, max input, accuracy

% This line is uncommented for the mask script.
set_param(gcb,'MaskDisplay',"disp(sprintf('Programmable Look-Up Table\nMemory Used = %d fixed point numbers\nInput Bounds: %.2d <= x <= %.2d\n Maximum Error: %.2d %', 2^RAM_SIZE, min_val, max_val, 100*maxErr)); port_label('input',1,'Data_In'); port_label('input',2,'Table_Wr_Data'); port_label('input',3,'Table_Wr_Addr'); port_label('input',4,'Table_Wr_En'); port_label('output',1,'Data_Out'); port_label('output',2,'Table_RW_Dout');")

