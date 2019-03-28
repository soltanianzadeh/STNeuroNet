%
% Please cite this paper if you use any component of this software:
% S. Soltanian-Zadeh, K. Sahingur, S. Blau, Y. Gong, and S. Farsiu, "Fast 
% and robust active neuron segmentation in two-photon calcium imaging using 
% spatio-temporal deep learning," Submitted to PNAS.
%
% Released under a GPL v2 license.

  function SelectNeuron_Allen(img,Mask,Trace)

    global i previous;
    global result resultString resultSpTimes; 
    global gui data1; 
    global CallBackInterrupted; CallBackInterrupted = 0;
    global IsPlaying
    global timeline; timeline = [];

       %bin input video for faster visualization
    scale = 3;
%     FR = 6/scale;
    img = uint16(binVideo_temporal(img,scale));
    Trace = double(binTraces_temporal(Trace,scale));
    
    %adjust contrast of frames
    for ii = 1:size(img,3)
        img(:,:,ii)=imadjust(img(:,:,ii),[],[],0.5);
    end
    
    [data1.d1,data1.d2, data1.T] = size(img);
    data1.T = size(Trace,2);
    data1.tracelimitx = [ 1, data1.T ];
    data1.tracelimity = [floor(min(Trace(:))) ceil(max(Trace(:)))];
    data1.green = cat(3, zeros(data1.d1,data1.d2),ones(data1.d1,data1.d2), zeros(data1.d1,data1.d2));
    
    MAXImg = imadjust(max(img,[],3),[],[],1.2);
    data1.maxImg = imadjust(max(img,[],3),[],[],1.2);

    i = find(result==2,1);
    if isempty(i)
        i = 1;
        previous = 0;
    else
        previous = max(1,i-1);
    end
    
    createInterface();
    updateInterface();
    
    %-------------------------------------------------------------------------%
        function createInterface( )

            gui = struct();
            screensize = get(groot,'ScreenSize');
            gui.Window = figure( ...
                'Name', 'Select Neurons', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'HandleVisibility', 'off',...
                'Position',[screensize(3)/9 screensize(4)/9 screensize(3)*7/9 screensize(4)*7/9]...
                );    

            % Arrange the main interface
            mainLayout = uix.VBoxFlex(...
                'Parent', gui.Window,...
                'Spacing', 3 );
            upperLayout = uix.HBoxFlex( ...
                'Parent', mainLayout, ...
                'Padding',3);
            lowerLayout = uix.HBoxFlex(...
                'Parent',mainLayout,...
                'Padding',3);

            % Upper Layout Design
            gui.MaskPanel = uix.BoxPanel(...
                'Parent',upperLayout,...
                'Padding',3,... 
                'Title','Mask');
            gui.MaskAxes = axes( 'Parent', gui.MaskPanel );

            gui.VideoPanel = uix.BoxPanel(...
                'Parent',upperLayout,...
                'Title','Video');
            gui.VideoAxes = axes(...
                'Parent',gui.VideoPanel,...
                'ButtonDownFcn',@PlayVideo,...
                'HitTest','on');

            gui.ListPanel = uix.VBoxFlex(...
                'Parent',upperLayout);
            gui.ListBox = uicontrol(...
                'Style','ListBox',...
                'Parent',gui.ListPanel,...
                'FontSize',10,...
                'String',{1,2,3,4,5,6,7,8,9,10},...
                'CallBack',@SelectList);
            gui.ListFB = uix.HBoxFlex(...
                'Parent',gui.ListPanel,...
                'Padding',3);
            gui.ListForward = uicontrol(...
                'Parent',gui.ListFB,...
                'Style','PushButton',...
                'String','Forward',...
                'CallBack',@Forward);
            gui.ListBackward = uicontrol(...
                'Parent',gui.ListFB,...
                'Style','PushButton',...
                'String','Backward',...
                'CallBack',@Backward);
            set(gui.ListPanel,'Heights',[-5 -1]);

            set(upperLayout,'Widths',[-2 -2 -1]);

            % Lower Layout Design
            gui.TracePanel = uix.BoxPanel(...
                'Parent',lowerLayout,...
                'Title','Trace');
            gui.TraceAxes = axes( 'Parent', gui.TracePanel );

            gui.ControlPanel = uix.HBoxFlex(...
                'Parent',lowerLayout);   
            gui.PlayButton = uicontrol(...
                'Style','PushButton',...
                'Parent',gui.ControlPanel,...
                'String','Play',...
                'CallBack',@PlayVideo);
            gui.YesButton = uicontrol(...
                'Style','PushButton',...
                'Parent',gui.ControlPanel,...
                'String','Yes',...
                'CallBack',@PushYesButton);
            gui.NoButton = uicontrol(...
                'Style','PushButton',...
                'Parent',gui.ControlPanel,...
                'String','No',...
                'CallBack',@PushNoButton);
             gui.MaybeButton = uicontrol(...
                'Style','PushButton',...
                'Parent',gui.ControlPanel,...
                'String','Maybe',...
                'CallBack',@PushMaybeButton);             
            gui.SpikeButton = uicontrol(...
                'Style','PushButton',...
                'Parent',gui.ControlPanel,...
                'String','Spike Times',...
                'CallBack',@PushSpikeButton); 
          
            set(lowerLayout,'Widths',[-2.5 -1]);
        end % createInterface

    %-------------------------------------------------------------------------%
        function updateInterface()
            if previous >0                
                if floor(i) ~= floor(previous)
                    setListBox(previous)
                    pause(0.3);
                end
            end

            % Update the Trace
            cla(gui.TraceAxes);
            data1.trace = Trace(i,:);
            plot(gui.TraceAxes,data1.trace);
            hold(gui.TraceAxes,'on');

            [data1.pk,data1.lk] = findpeaks(data1.trace,1:data1.T,'MinPeakDistance',50,'MinPeakProminence',1);
            if ~isempty(data1.lk)
                plot(gui.TraceAxes,data1.lk,data1.pk,'v');
%                 text(gui.TraceAxes,data1.lk+10,data1.pk,num2str((1:numel(data1.pk))'));
                title(gui.TraceAxes,'Have proper peak');
                mm = normalizeValues(mean(img(:,:,data1.lk),3));
                mm = imadjust(mm,stretchlim(mm,0.002),[]);
                data1.maxImg = imadjust(mm,[],[],0.5);
            else
                title(gui.TraceAxes,'Don''t have proper peak');
                data1.maxImg = MAXImg;
            end
            xlabel(gui.TraceAxes,'time(s)');
            ylabel(gui.TraceAxes,'deltaf/f*100');
            set(gui.TraceAxes,...
                'Xlim',data1.tracelimitx,'Ylim',[floor(min(data1.trace)),ceil(max(data1.trace))],...
                'Units','normalized','Position',[0.1 0.15 0.8 0.7]);

            % Update Video
            cla(gui.VideoAxes);
            mask = Mask(:,:,i);
            
            data1.mask = mat2gray(mask);
            bw = mask;
            bw(bw>0) = 1;
            temp = regionprops(bw,data1.mask,'WeightedCentroid');
            if isempty(temp)
                temp1 = reshape((mean(data1.mask,1)>0),1,[]);
                size(temp1)
                [~,temp2] = find(temp1,1);
                [~,temp3] = find(temp1,1,'last');

                data1.center(1) = mean([temp2 temp3]);
                temp1 = reshape((mean(mask,2)>0),1,[]);
                size(temp1)
                [~,temp2] = find(temp1,1);
                [~,temp3] = find(temp1,1,'last');

                data1.center(2) = mean([temp2 temp3]);
            else
                data1.center = round(temp.WeightedCentroid);
            end
% 
%             data1.boxy1 = 1;
%             data1.boxy2 = data1.d2;
%             data1.boxx1 = 1;
%             data1.boxx2 = data1.d1;
            data1.boxy1 = max(data1.center(1)-60,1) ;
            data1.boxy2 = min(data1.center(1)+60,data1.d2);
            data1.boxx1 = max(data1.center(2)-60,1);
            data1.boxx2 = min(data1.center(2)+60,data1.d1) ;

            if ~isempty(data1.lk)
                imagesc(gui.VideoAxes,img(data1.boxx1:data1.boxx2,data1.boxy1:data1.boxy2,max(data1.lk(1)-30,1)));
            else
                imagesc(gui.VideoAxes,img(data1.boxx1:data1.boxx2,data1.boxy1:data1.boxy2,1));
            end

            colormap(gui.VideoAxes,gray);
            hold(gui.VideoAxes,'on');

            data1.videomask = data1.mask(data1.boxx1:data1.boxx2,data1.boxy1:data1.boxy2);
            data1.smallgreen = data1.green(data1.boxx1:data1.boxx2,data1.boxy1:data1.boxy2,:);
            gui.smallgreen = image(gui.VideoAxes, data1.smallgreen,'Alphadata',data1.videomask);

            set(gui.VideoAxes,'DataAspectRatio',[1 1 1],...
                              'Xlim',[1 size(data1.videomask,2)],    'Ylim',[1 size(data1.videomask,1)],...
                              'XTick',1:20:size(data1.videomask,2),  'YTick',size(data1.videomask,1),...
                              'XTickLabel',data1.boxy1:20:data1.boxy2,'YTickLabel',data1.boxx1:20:data1.boxx2);

            gui.rectangle = rectangle(gui.VideoAxes,'Position',[data1.center(1)-data1.boxy1-6,data1.center(2)-data1.boxx1-6,13,13],'EdgeColor','yellow');
            hold(gui.VideoAxes,'off');

            % Update the Mask
            data1.masky1 = max(data1.center(1)-30,1);
            data1.masky2 = min(data1.center(1)+30,data1.d2);
            data1.maskx1 = max(data1.center(2)-30,1);
            data1.maskx2 = min(data1.center(2)+30,data1.d1);

            thr = 0.5;
            mask = data1.mask(data1.maskx1:data1.maskx2,data1.masky1:data1.masky2);
            axes(gui.MaskAxes);  
%             imagesc(gui.MaskAxes,mask);
            mm =data1.maxImg(data1.maskx1:data1.maskx2,data1.masky1:data1.masky2);
            imshow(mm, 'Parent', gui.MaskAxes,'DisplayRange',[]);
%             imagesc(gui.MaskAxes,data1.maxImg(data1.maskx1:data1.maskx2,data1.masky1:data1.masky2));
            colormap(gui.MaskAxes,gray);
            hold(gui.MaskAxes,'on');           
            contour(gui.MaskAxes,mask,1,'LineColor','y', 'linewidth',1);
%             mask_temp = medfilt2(mask,[3,3]);
%             mask_temp = mask_temp(:);
%             [temp,ind] = sort(mask_temp(:).^2,'ascend');
%             temp =  cumsum(temp);
%             ff = find(temp > (1-thr)*temp(end),1,'first');
%             if ~isempty(ff)
%                 contour(gui.MaskAxes,reshape(mask_temp,size(mask)),[0,0]+mask_temp(ind(ff)),'LineColor','y', 'linewidth',1);
%             end
            set(gui.MaskAxes,...
                'DataAspectRatio',[1 1 1],...
                'XLim',[1 data1.masky2-data1.masky1+1],'YLim',[1 data1.maskx2-data1.maskx1+1 ],...
                'Units','normalized','Position',[0.1 0.15 0.8 0.7]);
            hold(gui.MaskAxes,'on');
            title(gui.MaskAxes,sprintf('Number: %d',i));

            %% Update List Box
            setListBox(i);
            IsPlaying = 0;
        end % updateInterface

    %-------------------------------------------------------------------------%
        function PlayVideo( src ,~)

            if ishandle(timeline); delete(timeline); end
            if ~isempty(data1.lk)
                playduration = [max(data1.lk(1)-60,1) min(data1.lk(end)+60,size(Trace,2))];
            else
                playduration = [1 data1.T];
            end

            hold(gui.VideoAxes,'on');
            gui.rectangle = rectangle(gui.VideoAxes,'Position',[data1.center(1)-data1.boxy1-6,data1.center(2)-data1.boxx1-6,13,13],'EdgeColor','yellow');
            gui.smallgreen = image(gui.VideoAxes, data1.smallgreen,'Alphadata',data1.videomask);

            pause(0.4);
            delete(gui.smallgreen);
            pause(0.4);
            hold(gui.VideoAxes,'off');
            currentylim = get(gui.TraceAxes,'Ylim');
            temp = img(data1.boxx1:data1.boxx2,data1.boxy1:data1.boxy2,:);
            cmin = min(temp(:)); cmax = 0.6*max(temp(:));
            
            for j = playduration(1):playduration(2)
                IsPlaying = 1;
                imgShow = img(data1.boxx1:data1.boxx2,data1.boxy1:data1.boxy2,j);
                imagesc(gui.VideoAxes,imgShow);
                set(gui.VideoAxes,'CLim',[cmin,cmax]);
                hold(gui.VideoAxes,'on');
                if ~isempty(find(abs(j-data1.lk)<20,1))
                    gui.rectangle = rectangle(gui.VideoAxes,'Position',[data1.center(1)-data1.boxy1-6,data1.center(2)-data1.boxx1-6,13,13],'EdgeColor','red');
                else
                    gui.rectangle = rectangle(gui.VideoAxes,'Position',[data1.center(1)-data1.boxy1-6,data1.center(2)-data1.boxx1-6,13,13],'EdgeColor','yellow');
                end
                set(gui.VideoAxes,'DataAspectRatio',[1 1 1],...
                    'Xlim',[1 size(data1.videomask,2)],    'Ylim',[1 size(data1.videomask,1)],...
                    'XTick',1:30:size(data1.videomask,2),  'YTick',1:30:size(data1.videomask,1),...
                    'XTickLabel',data1.boxy1:30:data1.boxy2,'YTickLabel',data1.boxx1:30:data1.boxx2);
                colormap(gui.VideoAxes,gray);

                timeline = plot(gui.TraceAxes,[j j],currentylim,'-','Color','red');
                pause(0.008);
                delete(timeline);

                if CallBackInterrupted 
                    CallBackInterrupted = 0; IsPlaying = 0; return;
                end
                
                %To prevent freeze in video
                 hold(gui.VideoAxes,'off');
            end
        end

    %-------------------------------------------------------------------------%
        function SelectList( src, ~ )
            previous = i;
            temp = get( src, 'Value' );
            if floor(i/10) == 0
                i = temp;
            else
                i = temp + floor(i/10)*10-1;
            end
            updateInterface();

        end 

    %-------------------------------------------------------------------------%
        function PushYesButton(~, ~ )
            result(i) = 1;
            resultString{i} = sprintf('%d Yes',i);
            previous = i;
%             i = previous +1;
            i = find(result==2,1);
            if IsPlaying
                CallBackInterrupted = 1;
            end
            
            if ~isempty(i)
                updateInterface();
            else
                close(gui.Window);
            end

        end 

    %-------------------------------------------------------------------------%
        function PushNoButton( ~, ~ )
            result(i) = 0;
            resultString{i} = sprintf('%d No',i);
            previous = i;
%             i = previous +1;
            i = find(result==2,1);
            if IsPlaying
                CallBackInterrupted = 1;
            end
            if ~isempty(i)
                updateInterface();
            else
                close(gui.Window);
            end

        end 
    %-------------------------------------------------------------------------%
        function PushMaybeButton( ~, ~ )
            result(i) = -1;
            resultString{i} = sprintf('%d Maybe',i);
            previous = i;
            i = find(result==2,1);
            if IsPlaying
                CallBackInterrupted = 1;
            end
            if ~isempty(i)
                updateInterface();
            else
                close(gui.Window);
            end

        end 
    
    %-------------------------------------------------------------------------%
      function PushSpikeButton( ~, ~ )
          if IsPlaying
              CallBackInterrupted = 1;
          end   
          
          [spikeTimes,~] = getpts(gui.TraceAxes);
          %AVoid saving clicks outside of the time-limits
          ind = find(spikeTimes>=0 & spikeTimes<=data1.T);
          resultSpTimes{i} = spikeTimes(ind)*scale;  %convert back to 6Hz  
          
      end
  
    %-------------------------------------------------------------------------%
        function Forward(~,~)
            section = floor(i/10);
            previous = i;
            if section < floor(size(Trace,1)/10)
                section = section + 1;
                if (section == floor(size(Trace,1)/10))
                    duration = (section*10):size(Trace,1);
                else
                    duration = (section*10):(section*10+9);
                end 
                
                set(gui.ListBox,'String',resultString(duration));
                value = find(result(duration)==2,1);
                if isempty(value)
                   set(gui.ListBox,'Value',1);
                   i = 10*section;
                else
                   set(gui.ListBox,'Value',value);
                   i = 10*section + value-1;
                end
            end
            updateInterface();
        end

    %-------------------------------------------------------------------------%
        function Backward(~,~)
            section = floor(i/10);
            previous = i;
            if section > 2
                section = section - 1;
                duration = (section*10):(section*10+9);
                set(gui.ListBox,'String',resultString(duration));
                value = find(result(duration)==2,1);
                if isempty(value)
                   set(gui.ListBox,'Value',1);
                   i = 10*section;
                else
                   set(gui.ListBox,'Value',value);
                   i = 10*section + value-1;
                end
            elseif section == 1
                section = 0;
                duration = 1:9;
                set(gui.ListBox,'String',resultString(duration));
                value = find(result(duration)==2,1);
                if isempty(value)
                   set(gui.ListBox,'Value',1);
                   i = 1;
                else
                   set(gui.ListBox,'Value',value);
                   i = value;
                end
            end
            updateInterface();
        end             

    %-------------------------------------------------------------------------%
        function setListBox(num)
            tempsection = floor(num/10);
            if tempsection > 0
                set(gui.ListBox,'String',resultString(tempsection*10:min(size(Mask,3),tempsection*10+9)));
                set(gui.ListBox,'Value',mod(num,10)+1);
            else
                set(gui.ListBox,'String',resultString(1:end));
                set(gui.ListBox,'Value',mod(num,10));
            end
        end
    end