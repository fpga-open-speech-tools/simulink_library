% making some plots for the final documentation, ran after LinearPLUTInitTesting.m

% define the random input set
randSet = 2*rand(1,50);

% identify the values of the function at xTest
randOuts = sin(randSet);

% Find lookup addresses for each point in xTest
addrRands = zeros(1,length(randSet));
for it = 1:length(randSet)
    addrRands(it) = 2^RAM_SIZE;
    while(randSet(it) < xIn(addrRands(it)) && addrRands(it) ~= 1)
        addrRands(it) = addrRands(it) - 1;
    end
    if(addrRands(it)==0) %% sanity check for out of bounds results
        addrRands(it) = 1;
    end
end

% Check for any possible out of bounds errors (handled similarly in
% hardware)
%addrRands(addrRands == 2^RAM_SIZE) = 2^RAM_SIZE -1;

yRands = tableInit(addrRands);




% plotting
figure(3);
plot(xIn, 0:15, 'k*', randSet, addrRands-1, 'b.')
xlabel('Input value');
ylabel('Address Assigned');
title('Input to Address Mapping, Linear Scale');

figure(4);
plot(xIn, tableInit, 'k*', randSet, yRands, 'b.')
xlabel('Input value');
ylabel('Output value');
title('Input to Output, No Interpolation');