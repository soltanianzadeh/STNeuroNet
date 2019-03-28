%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.


function AddROI(Images,name,masks)

global CallBackInterrupted; CallBackInterrupted = 0;
global IsPlaying

corrImages = correlation_img(Images);
Images = uint16(binVideo_temporal(Images,3));   %bin to 2Hz for faster visualization
Images = homo_filt(Images,30);
meanImages = mean(Images,3);
meanImages = normalizeValues(meanImages);
meanImages = imadjust(meanImages,stretchlim(meanImages,0.002),[]);

maxImages = normalizeValues(max(Images,[],3));
maxImages = imadjust(maxImages,[0,0.5],[]);


% Adjust contrast
Images = normalizeValues(Images);
for k = 1:size(Images,3)
    Images(:,:,k) = imadjust(Images(:,:,k),[],[],0.5);
end

% setup
screensize = get(groot,'ScreenSize');
fig = figure('units','normalized','outerposition',[0 0 1 1],'Visible','Off');
% set(gcf,'Position',[300,300,960,480]);
% set(gcf,'PaperPosition',[300,300,960,480]);
myhandles = guihandles(fig);
myhandles.deleteIDs = [];
guidata(fig,myhandles) 

% Add push button to Choose which image to display
pos = [1750/1920*screensize(3),900/1080*screensize(4),...
    100/1920*screensize(3),40/1080*screensize(4)];
del = uicontrol('Style','pushbutton',...
      'Position', pos,...
       'String', 'Max image',...
       'Callback', @MAXIMG);
   
% Add push button to Choose which image to display
pos = [1750/1920*screensize(3),850/1080*screensize(4),...
    100/1920*screensize(3),40/1080*screensize(4)];
del = uicontrol('Style','pushbutton',...
      'Position', pos,...
       'String', 'Mean image',...
       'Callback', @MEANIMG);
   
  % Add push button to Choose which image to display
pos = [1750/1920*screensize(3),800/1080*screensize(4),...
    100/1920*screensize(3),40/1080*screensize(4)];
del = uicontrol('Style','pushbutton',...
      'Position', pos,...
       'String', 'Correlation image',...
       'Callback', @CORRIMG); 
   
   
% Add push button to give opportunity to add neurons
pos = [1750/1920*screensize(3),750/1080*screensize(4),...
    100/1920*screensize(3),40/1080*screensize(4)];
del = uicontrol('Style','pushbutton',...
      'Position', pos,...
       'String', 'Add neurons',...
       'Callback', @addID);
   
% Add push button to indicate end of work
pos = [1750/1920*screensize(3),700/1080*screensize(4),...
    100/1920*screensize(3),40/1080*screensize(4)];
del = uicontrol('Style','pushbutton',...
      'Position', pos,...
       'String', 'Finished',...
       'Callback', @savedata);
   
% Add push button to indicate end of work
pos = [1750/1920*screensize(3),550/1080*screensize(4),...
    100/1920*screensize(3),40/1080*screensize(4)];
del = uicontrol('Style','pushbutton',...
      'Position', pos,...
       'String', 'Play',...
       'Callback', @PlayVideo);
   
  %%%%%%%%  
FinalMasks = masks;

% Make figure visible after adding all components
fig.Visible = 'on';
subplot(1,2,1),
imshow(Images(:,:,1),[]);
MAXIMG;

    function MAXIMG(source,callbackdata)
        if IsPlaying
          CallBackInterrupted = 1;
        end
        
        subplot(1,2,2),
        imshow((maxImages),[]); 
        axis square;
        colormap gray
        
        hold on
        tempM = max(FinalMasks,[],3);
        image(cat(3,zeros(size(tempM)),ones(size(tempM)),zeros(size(tempM))),...
            'Alphadata',0.1*tempM);  
        hold off
    end

    function MEANIMG(source,callbackdata)
        if IsPlaying
          CallBackInterrupted = 1;
        end
        
        subplot(1,2,2),
        imshow((meanImages),[]); 
        axis square;
        colormap gray
        
        hold on
        tempM = max(FinalMasks,[],3);
        image(cat(3,zeros(size(tempM)),ones(size(tempM)),zeros(size(tempM))),...
            'Alphadata',0.1*tempM);   
        hold off
    end

    function CORRIMG(source,callbackdata)
        if IsPlaying
          CallBackInterrupted = 1;
        end
        
        subplot(1,2,2),
        imshow((corrImages),[]); 
        axis square;
        colormap gray
        
        hold on
        tempM = max(FinalMasks,[],3);
        image(cat(3,zeros(size(tempM)),ones(size(tempM)),zeros(size(tempM))),...
            'Alphadata',0.1*tempM);   
        hold off
    end
	
    function addID(source,callbackdata)
        if IsPlaying
          CallBackInterrupted = 1;
        end
        
        subplot(1,2,2);
        hFH = imfreehand();
        imH = imhandles(fig);
        temp = hFH.createMask(imH(1));
        if nnz(temp)
            FinalMasks = cat(3,FinalMasks,temp);
        end
        
        tempM = max(FinalMasks,[],3);
        subplot(1,2,2),
        hold on
        image(cat(3,zeros(size(tempM)),ones(size(tempM)),zeros(size(tempM))),...
            'Alphadata',0.1*tempM);  
    end

    function PlayVideo( source,callbackdata)

        subplot(1,2,1),
        ax = gca;
        cla

        tempM = max(FinalMasks,[],3);
        greenImg = cat(3,zeros(size(tempM)),ones(size(tempM)),zeros(size(tempM)));
        cmin = min(Images(:)); cmax = max(Images(:));
                
        for j = 1:size(Images,3)
            IsPlaying = 1;
            tempImg = Images(:,:,j);
            imagesc(ax,tempImg);
            caxis([cmin,cmax]);
            colormap gray;
            axis square
            
            hold on;
            image(greenImg,'Alphadata',0.1*tempM); 
            hold off;
            drawnow;
            pause(1/40);
            if CallBackInterrupted 
                CallBackInterrupted = 0; IsPlaying = 0; return;
            end            
        end
    end


    function savedata(source,callbackdata)
        if IsPlaying
          CallBackInterrupted = 1;
        end
        
        save(name,'FinalMasks');
        close(fig)
    end


end