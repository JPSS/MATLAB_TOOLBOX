function [ fitresult, gof, output] = generalFit2D( fitType, xData, yData, lowerBounds, upperBounds, startPoints )
%generalFit2D fits fittype to xdata, ydata using lower bounds, upper bounds
%and startpoints

[xData, yData] = prepareCurveData( xData, yData );

ft = fitType;
opts = fitoptions( ft );
opts.Display = 'Off';
opts.Lower = lowerBounds;
opts.StartPoint = startPoints;
opts.Upper = upperBounds;

% Fit model to data.
[fitresult, gof, output] = fit( xData, yData, ft, opts );

end

