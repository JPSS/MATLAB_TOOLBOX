function [ jsonData ] = load_cadnano()
%% loads cadnano .json file
%   loads .json file using loadjson(), adds fields to jsonData structure 
%
%   .nrHelices is number of selected helices in cadnano design
%   .lenHelix is number of selected bases in cadnano design
%   .diameter is helix diameter used for calculation of helix positions
%   .pathname is pathname to .json file
%   .filename is filename of .json file
%   .latticeType is square or honeycomb
%   .vstrand{i}.doubleStranded is array of 0/1, 1=basepair in helix i
%   .basePairs is number of basepairs in design (all regions with both staple and scaffold strands)
%
%   returns augmented jsonData structure

[filename, pathname]=uigetfile('*.json','Select cando file');
jsonData=loadjson([pathname filename]);                             %load .json file using loadjson() from jsonlab

latticeType=questdlg('lattice type?','honeycomb','honeycomb','square','square');

jsonData.('nrHelices')=length(jsonData.vstrands);
jsonData.('lenHelix')=length(jsonData.vstrands{1}.stap);
jsonData.('diameter')=2.6;                                          %double stranded helix diameter
jsonData.('pathname')=pathname;
jsonData.('filename')=filename;
jsonData.('latticeType')=latticeType;

basePairs=0;
for currHelix=1:jsonData.nrHelices
    row=jsonData.vstrands{currHelix}.row;
    col=jsonData.vstrands{currHelix}.col;
    
    if strcmp(latticeType,'honeycomb')                              %calculate x and y positions of helices in honeycomb lattice
        jsonData.vstrands{currHelix}.('xPos')=col*sqrt(3)*0.5*jsonData.diameter;
        jsonData.vstrands{currHelix}.('yPos')=+((-1)^(col+row))*jsonData.diameter*0.25-row*1.5*jsonData.diameter;
    else                                                            %calculate x and y positions of helices in square lattice
        jsonData.vstrands{currHelix}.('xPos')=col*jsonData.diameter;
        jsonData.vstrands{currHelix}.('yPos')=-row*jsonData.diameter;
    end
    
    doubleStranded=zeros(jsonData.lenHelix,1);                      %determine basepair locations
    for currBase=1:jsonData.lenHelix
        doubleStranded(currBase)=(jsonData.vstrands{currHelix}.stap(currBase,1)~=-1 || jsonData.vstrands{currHelix}.stap(currBase,3)~=-1) && ...
                (jsonData.vstrands{currHelix}.scaf(currBase,1)~=-1 || jsonData.vstrands{currHelix}.scaf(currBase,3)~=-1);
    end
    jsonData.vstrands{currHelix}.('doubleStranded')=doubleStranded;
    
    basePairs=basePairs+sum(doubleStranded);
end

jsonData.('basePairs')=basePairs;



