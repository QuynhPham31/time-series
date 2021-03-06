function EMD_ANN(inputSeries,targetSeries)
Len=size(targetSeries,1);
TT=targetSeries;
imf=emd(targetSeries,1);
targetSeries=targetSeries-imf(end,:)'+mean(imf(end,:));
inputSeries = tonndata(inputSeries,false,false);
targetSeries = tonndata(targetSeries,false,false);
% Create a Nonlinear Autoregressive Network with External Input
inputDelays = 1:4;
feedbackDelays = 1:4;
hiddenLayerSize = 10;
net = narxnet(inputDelays,feedbackDelays,hiddenLayerSize);

% Prepare the Data for Training and Simulation
% The function PREPARETS prepares time series data 
% for a particular network, shifting time by the minimum 
% amount to fill input states and layer states.
% Using PREPARETS allows you to keep your original 
% time series data unchanged, while easily customizing it 
% for networks with differing numbers of delays, with
% open loop or closed loop feedback modes.
[inputs,inputStates,layerStates,targets] = ... 
    preparets(net,inputSeries,{},targetSeries);

% Set up Division of Data for Training, Validation, Testing
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;

% Train the Network
[net,tr] = train(net,inputs,targets,inputStates,layerStates);

% Test the Network
outputs = net(inputs,inputStates,layerStates);
errors = gsubtract(targets,outputs);
performance = perform(net,targets,outputs);

% View the Network
%view(net)
c=cell2mat(outputs);
mape=100/size(cell2mat(targets),2)*sum(abs(cell2mat(targets)-c)./cell2mat(targets));
rmse=1/size(cell2mat(targets),2)*sqrt((cell2mat(targets)-c)*(cell2mat(targets)-c)');
%% Results
figure;
plot(cell2mat(targets),'b');
hold on; plot(c,'r');
title(['EMD_ANN model(mape=', num2str(mape),', rmse=',num2str(rmse),')']);
legend( 'ANN Result','EMD Result');
emd(c',4);

% Plots
% Uncomment these lines to enable various plots.
% figure, plotperform(tr)
% figure, plottrainstate(tr)
%figure, plotregression(targets,outputs)
% figure, plotresponse(targets,outputs)
% figure, ploterrcorr(errors)
% figure, plotinerrcorr(inputs,errors)

% Closed Loop Network
% Use this network to do multi-step prediction.
% The function CLOSELOOP replaces the feedback input with a direct
% connection from the output layer.
% netc = closeloop(net);
% netc.name = [net.name ' - Closed Loop'];
% view(netc)
% [xc,xic,aic,tc] = preparets(netc,inputSeries,{},targetSeries);
% yc = netc(xc,xic,aic);
% closedLoopPerformance = perform(netc,tc,yc);

% Early Prediction Network
% For some applications it helps to get the prediction a 
% timestep early.
% The original network returns predicted y(t+1) at the same 
% time it is given y(t+1).
% For some applications such as decision making, it would 
% help to have predicted y(t+1) once y(t) is available, but 
% before the actual y(t+1) occurs.
% The network can be made to return its output a timestep early 
% by removing one delay so that its minimal tap delay is now 
% 0 instead of 1.  The new network returns the same outputs as 
% the original network, but outputs are shifted left one timestep.
% nets = removedelay(net);
% nets.name = [net.name ' - Predict One Step Ahead'];
% view(nets)
% [xs,xis,ais,ts] = preparets(nets,inputSeries,{},targetSeries);
% ys = nets(xs,xis,ais);
% earlyPredictPerformance = perform(nets,ts,ys);



end