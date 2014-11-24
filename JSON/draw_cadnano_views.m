function [  ] = draw_cadnano_views( jsonData )
%% draws side views and pseudo-3d view of cadnano design into .svg file
%   input: jsonData returned by load_cadnano()
%   ouput: empty

%length of a basepair used for drawing
lenBasepair=0.34;

nrHelices=jsonData.nrHelices;
lenHelix=jsonData.lenHelix;

xPositions=zeros(1,nrHelices);
yPositions=zeros(1,nrHelices);

%collect x and y positions of helices 
for currHelix=1:nrHelices
    xPositions(currHelix)=jsonData.vstrands{currHelix}.xPos;
    yPositions(currHelix)=jsonData.vstrands{currHelix}.yPos;
end

%invert yPos because illustrator yAxis positive direction is downwards
%move xPos and yPos towards 0
for currHelix=1:nrHelices
    jsonData.vstrands{currHelix}.xPos=jsonData.vstrands{currHelix}.xPos-min(xPositions);
    
    jsonData.vstrands{currHelix}.yPos=-jsonData.vstrands{currHelix}.yPos;
    jsonData.vstrands{currHelix}.yPos=jsonData.vstrands{currHelix}.yPos-min(yPositions);
end
%move xPos and yPos towards 0
xPositions=xPositions-min(xPositions);
yPositions=yPositions-min(yPositions);

%determine longest axis of side views
xMax=abs(max(xPositions));
yMax=abs(max(yPositions));
shift=max([xMax, yMax, lenHelix*lenBasepair]);

%sort helices such that furthest left is first element
[tmp, xSortIndices]=sort(xPositions);

%sort helices such that furthest down is first element
[tmp, ySortIndices]=sort(yPositions);

%sort helices such that furthest left first, furthest down second, is first element
[tmp, xySortIndices]=sortrows([xPositions.' yPositions.'],[1 2]);
xySortIndices=xySortIndices.';

%open file to draw into
fileId = fopen( [jsonData.pathname jsonData.filename(1:end-5) '_draw.svg' ], 'w' );

%xml start text (necessary?)
fprintf(fileId,['<?xml version="1.0" encoding="UTF-8"?>\n' ...
    '<svg version="1.1" baseProfile="full"\n' ...
	'width="200px" height="100px" viewBox="0 0 200 100">\n']);

%define gradients, colors
fprintf(fileId,['<defs>\n'...
    '<linearGradient id="grad1" x1="0%%" y1="0%%" x2="0%%" y2="100%%">\n'...
    '<stop offset="0%%" style="stop-color:rgb(255,128,0);stop-opacity:1"/>\n'...
    '<stop offset="100%%" style="stop-color:rgb(128,64,0);stop-opacity:1"/>\n'...
    '</linearGradient>\n'...
    '<linearGradient id="grad2" x1="0%%" y1="0%%" x2="0%%" y2="100%%">\n'...
    '<stop offset="0%%" style="stop-color:rgb(158,205,49);stop-opacity:1"/>\n'...
    '<stop offset="100%%" style="stop-color:rgb(82,125,36);stop-opacity:1"/>\n'...
    '</linearGradient>\n'...
    '<linearGradient id="color1" x1="0%%" y1="0%%" x2="0%%" y2="100%%">\n'...
    '<stop offset="0%%" style="stop-color:rgb(255,127,0);stop-opacity:1"/>\n'...
    '<stop offset="100%%" style="stop-color:rgb(255,127,0);stop-opacity:1"/>\n'...
    '</linearGradient>\n'...
    '<linearGradient id="color2" x1="0%%" y1="0%%" x2="0%%" y2="100%%">\n'...
    '<stop offset="0%%" style="stop-color:rgb(158,205,49);stop-opacity:1"/>\n'...
    '<stop offset="100%%" style="stop-color:rgb(158,205,49);stop-opacity:1"/>\n'...
    '</linearGradient>\n'...
    '</defs>\n']);

%draw scale bar
fprintf(fileId,'<g>\n');
fprintf(fileId,'<line x1="0" y1="0" x2="20" y2="0" stroke="black" stroke-width="1"/>\n');
fprintf(fileId,'<text x="2" y="5" fill="black" font-size="4" >20nm</text>/>\n');
fprintf(fileId,'</g>\n');

%draw each continous double helix, view from the right side
fprintf(fileId,'<g transform="translate(%f,%f)">\n',0,shift);
strand=0;
startPos=0;
for currHelix=xSortIndices
    for currBase=1:lenHelix
        if jsonData.vstrands{currHelix}.doubleStranded(currBase)==1
            if strand==0
                strand=1;
                startPos=currBase;
            end
        else
            if strand==1
                strand=0;
                endPos=currBase;
                fprintf( fileId, '<rect x="%f" y="%f" width="%f" height="%f" fill="url(#grad1)" stroke-width="0.0" stroke="none"/>\n' ...
                , startPos*lenBasepair, jsonData.vstrands{currHelix}.yPos, lenBasepair*(endPos-startPos+1), jsonData.diameter);
            end
        end
    end
    if strand==1
        endPos=lenHelix;
            fprintf( fileId, '<rect x="%f" y="%f" width="%f" height="%f" fill="url(#grad1)" stroke-width="0.0" stroke="none"/>\n' ...
            , startPos*lenBasepair, jsonData.vstrands{currHelix}.yPos, lenBasepair*(endPos-startPos+1), jsonData.diameter);
    end
end
fprintf(fileId,'</g>\n');

%draw each continous double helix, view from the top side
fprintf(fileId,'<g transform="translate(%f,%f)">\n',shift,shift);
strand=0;
startPos=0;
for currHelix=ySortIndices
    for currBase=1:lenHelix
        if jsonData.vstrands{currHelix}.doubleStranded(currBase)==1
            if strand==0
                strand=1;
                startPos=currBase;
            end
        else
            if strand==1
                strand=0;
                endPos=currBase;
                fprintf( fileId, '<rect x="%f" y="%f" width="%f" height="%f" fill="url(#grad1)" stroke-width="0.0" stroke="none"/>\n' ...
                , startPos*lenBasepair, jsonData.vstrands{currHelix}.xPos, lenBasepair*(endPos-startPos+1), jsonData.diameter);
            end
        end
    end
    if strand==1
        endPos=lenHelix;
            fprintf( fileId, '<rect x="%f" y="%f" width="%f" height="%f" fill="url(#grad1)" stroke-width="0.0" stroke="none"/>\n' ...
            , startPos*lenBasepair, jsonData.vstrands{currHelix}.xPos, lenBasepair*(endPos-startPos+1), jsonData.diameter);
    end    
end
fprintf(fileId,'</g>\n');

%draw each continous double helix, view from the front side
fprintf(fileId,'<g transform="translate(%f,%f)">\n',shift,0);
strand=0;
startPos=0;
for currHelix=ySortIndices
    for currBase=lenHelix:-1:1
        if jsonData.vstrands{currHelix}.doubleStranded(currBase)==1
            if strand==0
                strand=1;
                startPos=currBase;
            end
        else
            if strand==1
                strand=0;
                endPos=currBase;
                fprintf( fileId, '<circle cx="%f" cy="%f" r="%f" fill="url(#color1)" stroke-width="0.0" stroke="none"/>\n' ...
                , jsonData.vstrands{currHelix}.xPos, jsonData.vstrands{currHelix}.yPos, jsonData.diameter*0.5);
            end
        end
    end
    if strand==1
        endPos=1;
        fprintf( fileId, '<circle cx="%f" cy="%f" r="%f" fill="url(#color1)" stroke-width="0.0" stroke="none"/>\n' ...
        , jsonData.vstrands{currHelix}.xPos, jsonData.vstrands{currHelix}.yPos, jsonData.diameter*0.5);
    end    
end
fprintf(fileId,'</g>\n');

%draw each continous double helix, pseudo-3d view from top right
fprintf(fileId,'<g>\n');
strand=0;
startPos=0;
for currHelix=xySortIndices
    for currBase=lenHelix:-1:1
        if jsonData.vstrands{currHelix}.doubleStranded(currBase)==1
            if strand==0
                strand=1;
                startPos=currBase;
            end
        else
            if strand==1
                strand=0;
                endPos=currBase;
                fprintf( fileId, '<circle cx="%f" cy="%f" r="%f" fill="url(#grad1)" stroke-width="0.0" stroke="none" transform="rotate(-45,%f,%f)"/>\n' ...
                , jsonData.vstrands{currHelix}.xPos+startPos*lenBasepair/2, jsonData.vstrands{currHelix}.yPos-startPos*lenBasepair/2,...
                jsonData.diameter*0.5,jsonData.vstrands{currHelix}.xPos+startPos*lenBasepair/2, jsonData.vstrands{currHelix}.yPos-startPos*lenBasepair/2);
                
                fprintf( fileId, ['<rect x="%f" y="%f" width="%f" height="%f" fill="url(#grad1)" stroke-width="0.0" stroke="none"'...
                ' transform="rotate(-45,%f,%f)"/>\n'] ...
                , jsonData.vstrands{currHelix}.xPos+endPos*lenBasepair/2-jsonData.diameter/(2*sqrt(2)),...
                jsonData.vstrands{currHelix}.yPos-endPos*lenBasepair/2-jsonData.diameter/(2*sqrt(2)),...
                lenBasepair*(startPos-endPos+1)/sqrt(2), jsonData.diameter,...
                jsonData.vstrands{currHelix}.xPos+endPos*lenBasepair/2-jsonData.diameter/(2*sqrt(2)),...
                jsonData.vstrands{currHelix}.yPos-endPos*lenBasepair/2-jsonData.diameter/(2*sqrt(2)));
            
                fprintf( fileId, '<circle cx="%f" cy="%f" r="%f" fill="url(#color1)" stroke-width="0.05" stroke="black"/>\n' ...
                , jsonData.vstrands{currHelix}.xPos+endPos*lenBasepair/2, jsonData.vstrands{currHelix}.yPos-endPos*lenBasepair/2,...
                jsonData.diameter*0.5);
            end
        end
    end
    if strand==1
        endPos=1;
            fprintf( fileId, '<circle cx="%f" cy="%f" r="%f" fill="url(#grad1)" stroke-width="0.0" stroke="none" transform="rotate(-45,%f,%f)"/>\n' ...
            , jsonData.vstrands{currHelix}.xPos+startPos*lenBasepair/2, jsonData.vstrands{currHelix}.yPos-startPos*lenBasepair/2,...
            jsonData.diameter*0.5,jsonData.vstrands{currHelix}.xPos+startPos*lenBasepair/2, jsonData.vstrands{currHelix}.yPos-startPos*lenBasepair/2);

            fprintf( fileId, ['<rect x="%f" y="%f" width="%f" height="%f" fill="url(#grad1)" stroke-width="0.0" stroke="none"'...
            ' transform="rotate(-45,%f,%f)"/>\n'] ...
            , jsonData.vstrands{currHelix}.xPos+endPos*lenBasepair/2-jsonData.diameter/(2*sqrt(2)),...
            jsonData.vstrands{currHelix}.yPos-endPos*lenBasepair/2-jsonData.diameter/(2*sqrt(2)),...
            lenBasepair*(startPos-endPos+1)/sqrt(2), jsonData.diameter,...
            jsonData.vstrands{currHelix}.xPos+endPos*lenBasepair/2-jsonData.diameter/(2*sqrt(2)),...
            jsonData.vstrands{currHelix}.yPos-endPos*lenBasepair/2-jsonData.diameter/(2*sqrt(2)));

            fprintf( fileId, '<circle cx="%f" cy="%f" r="%f" fill="url(#color1)" stroke-width="0.05" stroke="black"/>\n' ...
            , jsonData.vstrands{currHelix}.xPos+endPos*lenBasepair/2, jsonData.vstrands{currHelix}.yPos-endPos*lenBasepair/2,...
            jsonData.diameter*0.5);
    end    
end
fprintf(fileId,'</g>\n');

fprintf(fileId,'</svg>');

fclose(fileId);
          

end
