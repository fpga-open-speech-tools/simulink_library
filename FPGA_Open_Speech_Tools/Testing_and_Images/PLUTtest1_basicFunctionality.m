%% Testing and Verification script for Log-Spaced Programmable Look-Up Table (PLUT)
% PLUTtest1_basicFunctionality.m
% This script is built for the testingPLUT.slx model.
% It tests and verifies the following functionality: 
%  - Sizing of Table for an initial given accuracy and function
%  - Initialization of memory
%  - Addressing scheme of log-spaced inputs 
%  - Linear Interpolation
%  - Accuracy of results 
% Reprogramming during runtime will be in a second script, PLUTtest2_reprogramming.m 

% Instructions for setting up the simulation given in "Testing of the PLUT Instructions.docx"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Before Running Simulation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;
% Run this section of code (ctrl + Enter) before running the simulation on testingPLUT.slx 
% Define Simulation variables
dataIn = 0:0.001:3;					% Input data range, note it includes 0 and goes beyond the upper "expected input" bound
ts = 1/48000; 						% sample time 
tt = 0:length(dataIn)-1;				
tt = tt.*ts;						% Note: Division tends to cause strange errors in simulation. Always use fixed-step time ts for consistent results.

% Setting up time series sets for Simulink inputs 
simin_Data_In = [tt',dataIn'];		
simin_Table_Wr_Data = [tt',zeros(length(dataIn),1)];	% no reprogramming the table during this test. Set these 3 to 0s
simin_Table_Wr_Addr = [tt',zeros(length(dataIn),1)];
simin_Wr_En = [tt',zeros(length(dataIn),1)];
stop_time = tt(end);

% Now run the simulation, ensure fixed step time and ending time of stop_time 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% After Running Simulation %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pull information out of the simulation workspace and set it up for graphs and analysis 
addrDelay = 1; 
output = out.Data_Out.Data(:);
outputIdeal = sqrt(dataIn);
address = addr.Data(:);
address(1:end-addrDelay) = address(addrDelay+1:end); % Simulation addresses take 1 sample of time to pipeline. This shifts them to line up with their respective inputs 
figure(3); plot(dataIn,address);
title("Read addresses as a function of input (Time Corrected)");
xlabel("Input");
ylabel("Read Address");

outputDelay = 3;
output(1:end-outputDelay) = output(1+outputDelay:end); % Simulation output takes 3 samples of time to pipeline. This shifts them to line up with their respective inputs 
figure(2); plot(dataIn,output, dataIn,outputIdeal);
title("Output Data over Input, sqrt Function (Time Corrected)");
xlabel("Input");
ylabel("Read Address");
legend("Table Output", "Ideal Output");

% Since expected inputs are bound between 2^-15 and 1, only consider the accuracy of points within that range 
% allowed_in = (dataIn <= 1) && (dataIn >= 2^-15);
above = dataIn >= 2^-15;
below = dataIn <= 1;
valid = above & below;

% identify addresses, outputs, and inputs associated with the expected input range 
validAddr = address(valid);
validOut = output(valid);
validOutIdeal = outputIdeal(valid);
validXIn = dataIn(valid);

% Identify error of those valid outputs 
err = (validOutIdeal - validOut')./validOutIdeal;
max_err = max(err) % not ;'d to allow printout 
figure(4); semilogx(validXIn, 100*err);
title("Output Error as a function of Input");
xlabel("Input");
ylabel("Output Error %");