function parameters = choose_gel_image_parameters(imageData, weight_factors)
%% select gel data loading parameters
%   INPUTS:
%   imageData from load_gel_image.m
%   weight_factors = cell array of weights for summation of different channels
%   OUTPUT:
%   parameters = struct with .pockets .dna_ladder_lanes .gel_area

image_sum = weight_factors{1}.*imageData.images{1};                           
for i=2:imageData.nrImages
  image_sum = image_sum + weight_factors{i}.*imageData.images{i};
end

%select area for lane determination
plot_image_ui(image_sum)                                        
title('Select pocket area')
h = imrect;
wait(h);
selectedArea = int32(getPosition(h));
delete(h);

title('Select 1st DNA ladder band')
h1 = impoint;
wait(h1);
setColor(h1,[255, 230, 230]./256);

title('Select 2nd DNA ladder band')
h2 = impoint;
wait(h2);
setColor(h2,[255, 153, 153]./256);

title('Select 3nd DNA ladder band')
h3 = impoint;
wait(h3);
setColor(h3,[255, 77, 77]./256);

title('Select 4th DNA ladder band')
h4 = impoint;
wait(h4);
setColor(h4,[255, 0, 0]./256);

title('Select 5th DNA ladder band')
h5 = impoint;
wait(h5);
setColor(h5,[179, 0, 0]./256);

title('Select 6th DNA ladder band')
h6 = impoint;
wait(h6);
setColor(h6,[102, 0, 0]./256);

dna_ladder_lanes = [int32(getPosition(h1)), int32(getPosition(h2)), int32(getPosition(h3)),...
    int32(getPosition(h4)), int32(getPosition(h5)), int32(getPosition(h6))];

parameters.pockets = selectedArea;
parameters.dna_ladder_lanes = dna_ladder_lanes(2:2:end);

distance_between_two_ladder_bands = parameters.dna_ladder_lanes(end) - parameters.dna_ladder_lanes(end - 1);
parameters.gel_area = [parameters.pockets(1:3) parameters.dna_ladder_lanes(end) + distance_between_two_ladder_bands];

imrect(gca, parameters.gel_area)
title('Good?')
pause
close
