function spikes = getWaveformsFromDat(spikes,session,unitsToProcess)
% Extracts raw waveforms from the binary file. 
% This function is a part of CellExplorer: https://cellexplorer.org/
%
% INPUTS
% Spikes struct:            https://cellexplorer.org/datastructure/data-structure-and-format/#spikes
% session metadata struct:  https://cellexplorer.org/datastructure/data-structure-and-format/#session-metadata
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 13-06-2020

basepath = session.general.basePath;
basename = session.general.name;
LSB = session.extracellular.leastSignificantBit;
nChannels = session.extracellular.nChannels;
sr = session.extracellular.sr;
electrodeGroups = session.extracellular.electrodeGroups.channels;
nElectrodeGroups = session.extracellular.nElectrodeGroups;
if isfield(session.extracellular,'fileName') && ~isempty(session.extracellular.fileName)
    fileNameRaw = session.extracellular.fileName;
else
    fileNameRaw = [basename '.dat'];
end

timerVal = tic;         
nPull = 600;            % number of spikes to pull out (default: 600)
wfWin_sec = 0.004;      % Larger size of waveform windows for filterning. total width in ms
wfWinKeep = 0.0008;     % half width in ms
filtFreq = [500,8000];  % Band pass filter
showWaveforms = true;   
badChannels = [];       

% Removing channels marked as Bad in session struct
if ~isempty(session) && isfield(session,'channelTags') && isfield(session.channelTags,'Bad')
    if isfield(session.channelTags.Bad,'channels') && ~isempty(session.channelTags.Bad.channels)
        badChannels = [badChannels,session.channelTags.Bad.channels];
    end
    if isfield(session.channelTags.Bad,'electrodeGroups') && ~isempty(session.channelTags.Bad.electrodeGroups)
        badChannels = [badChannels,electrodeGroups{session.channelTags.Bad.electrodeGroups}];
    end
    badChannels = unique(badChannels);
end

% Removing channels that does not exist in SpkGrps
if isfield(session.extracellular,'spikeGroups')
    badChannels = [badChannels,setdiff([electrodeGroups{:}],[session.extracellular.spikeGroups.channels{:}])];
end

if isempty(badChannels)
    goodChannels = 1:nChannels;
else
    goodChannels = setdiff(1:nChannels,badChannels);
end
nGoodChannels = length(goodChannels);

[b1, a1] = butter(3, filtFreq/sr*2, 'bandpass');
disp('Getting waveforms from dat file')
f = waitbar(0,['Getting waveforms from dat file'],'Name',['Processing ' basename]);
if showWaveforms
    fig1 = figure('Name', ['Getting waveforms for ' basename],'NumberTitle', 'off','position',[100,100,1000,800]);
end
wfWin = round((wfWin_sec * sr)/2);
t1 = toc(timerVal);
if ~exist(fullfile(basepath,fileNameRaw),'file')
    error(['Binary file missing: ', fullfile(basepath,fileNameRaw)])
end
s = dir(fullfile(basepath,fileNameRaw));

duration = s.bytes/(2*nChannels*sr);
rawData = memmapfile(fullfile(basepath,fileNameRaw),'Format','int16','writable',false);
% DATA = rawData.Data;

% Fit exponential
g = fittype('a*exp(-x/b)+c','dependent',{'y'},'independent',{'x'},'coefficients',{'a','b','c'});
if ~exist('unitsToProcess','var')
    unitsToProcess = 1:size(spikes.times,2);
end

for i = 1:length(unitsToProcess)
    ii = unitsToProcess(i);
    t1 = toc(timerVal);
    if isfield(spikes,'ts')
        spkTmp = spikes.ts{ii}(find(spikes.ts{ii}./sr > wfWin_sec/1.8 & spikes.ts{ii}./sr < duration-wfWin_sec/1.8));
    else
        spkTmp = round(sr * spikes.times{ii}(find(spikes.times{ii} > wfWin_sec/1.8 & spikes.times{ii} < duration-wfWin_sec/1.8)));
    end
    
    if length(spkTmp) > nPull
        spkTmp = spkTmp(randperm(length(spkTmp)));
        spkTmp = sort(spkTmp(1:nPull));
    end
    spkTmp = spkTmp(:);
    % Determines the maximum waveform channel from 100 waveforms across all good channels
    startIndicies1 = (spkTmp(1:min(100,length(spkTmp))) - wfWin)*nChannels+1;
    stopIndicies1 =  (spkTmp(1:min(100,length(spkTmp))) + wfWin)*nChannels;
    X1 = cumsum(accumarray(cumsum([1;stopIndicies1(:)-startIndicies1(:)+1]),[startIndicies1(:);0]-[0;stopIndicies1(:)]-1)+1);
    wf = LSB * mean(reshape(double(rawData.Data(X1(1:end-1))),nChannels,(wfWin*2),[]),3);
    wfF2 = zeros((wfWin * 2),nGoodChannels);
    for jj = 1 : nGoodChannels
        wfF2(:,jj) = filtfilt(b1, a1, wf(goodChannels(jj),:));
    end
    [~, idx] = max(max(wfF2)-min(wfF2)); % max(abs(wfF(wfWin,:)));
    spikes.maxWaveformCh1(ii) = goodChannels(idx);
    spikes.maxWaveformCh(ii) = spikes.maxWaveformCh1(ii)-1;
    
    % Assigning shankID to the unit
    for jj = 1:nElectrodeGroups
        if any(electrodeGroups{jj} == spikes.maxWaveformCh1(ii))
            spikes.shankID(ii) = jj;
        end
    end
    
    % Pulls the waveforms from all channels from the dat
    startIndicies2 = (spkTmp - wfWin)*nChannels+1;
    stopIndicies2 = (spkTmp + wfWin)*nChannels;
    X2 = cumsum(accumarray(cumsum([1;stopIndicies2(:)-startIndicies2(:)+1]),[startIndicies2(:);0]-[0;stopIndicies2(:)]-1)+1);
    wf = LSB * reshape(double(rawData.Data(X2(1:end-1))),nChannels,(wfWin*2),[]);
    wfF = zeros(nChannels,(wfWin * 2),length(spkTmp));
    for jjj = 1 : nChannels
        for jj = 1 : length(spkTmp)
            wfF(jjj,:,jj) = filtfilt(b1, a1, wf(jjj,:,jj));
        end
    end
    window_interval = wfWin-ceil(wfWinKeep*sr):wfWin-1+ceil(wfWinKeep*sr); % +- 0.8 ms of waveform
    window_interval2 = wfWin-ceil(1.5*wfWinKeep*sr):wfWin-1+ceil(1.5*wfWinKeep*sr); % +- 1.20 ms of waveform
    
    wf2 = mean(wf,3);
    rawWaveform_all = detrend(wf2 - mean(wf2,2));
    spikes.rawWaveform{ii} = rawWaveform_all(spikes.maxWaveformCh1(ii),window_interval);
    rawWaveform_std = std((wf(spikes.maxWaveformCh1(ii),:,:)-mean(wf(spikes.maxWaveformCh1(ii),:,:),3)),0,3);
    filtWaveform_all = mean(wfF,3);
    spikes.filtWaveform{ii} = filtWaveform_all(spikes.maxWaveformCh1(ii),window_interval);
    filtWaveform_std = std((wfF(spikes.maxWaveformCh1(ii),:,:)-mean(wfF(spikes.maxWaveformCh1(ii),:,:),3)),0,3);
    
    spikes.rawWaveform_all{ii} = rawWaveform_all(:,window_interval2);
    spikes.rawWaveform_std{ii} = rawWaveform_std(window_interval);
    spikes.filtWaveform_all{ii} = filtWaveform_all(:,window_interval2);
    spikes.filtWaveform_std{ii} = filtWaveform_std(window_interval);
    spikes.timeWaveform{ii} = ([-ceil(wfWinKeep*sr)*(1/sr):1/sr:(ceil(wfWinKeep*sr)-1)*(1/sr)])*1000;
    spikes.timeWaveform_all{ii} = ([-ceil(1.5*wfWinKeep*sr)*(1/sr):1/sr:(ceil(1.5*wfWinKeep*sr)-1)*(1/sr)])*1000;
    spikes.peakVoltage(ii) = range(spikes.filtWaveform{ii});
    spikes.channels_all{ii} = [1:nChannels];
    
    [B,I] = sort(range(spikes.filtWaveform_all{ii}(goodChannels,:),2),'descend');
    spikes.peakVoltage_sorted{ii} = zeros(1,nChannels);
    spikes.peakVoltage_sorted{ii}(1:length(goodChannels)) = B;
    spikes.maxWaveform_all{ii} = zeros(1,nChannels);
    spikes.maxWaveform_all{ii}(1:length(goodChannels)) = goodChannels(I);

    % Fitting peakVoltage sorted with exponential function with length constant
    nChannelFit = min([16,length(goodChannels),length(electrodeGroups{spikes.shankID(ii)})]);
    x = 1:nChannelFit;
    y = spikes.peakVoltage_sorted{ii}(x);
    if ~isempty(spikes.times{ii})
        f0 = fit(x',y',g,'StartPoint',[spikes.peakVoltage(ii), 5, 5],'Lower',[1, 0.001, 0],'Upper',[5000, 50, 1000]);
        fitCoeffValues = coeffvalues(f0);
        spikes.peakVoltage_expFitLengthConstant(ii) = fitCoeffValues(2);
    else
        spikes.peakVoltage_expFitLengthConstant(ii) = nan;
    end
    if ishandle(fig1)
        figure(fig1)
        subplot(2,3,1), hold off
        plot(wfF2), hold on, plot(wfF2(:,idx),'k','linewidth',2), title('Filtered waveforms across channels'), xlabel('Samples'), ylabel('uV'),hold off
        subplot(2,3,2), hold off,
        plot(permute(wfF(spikes.maxWaveformCh1(ii),:,:),[2,3,1])), hold on
        plot(mean(permute(wfF(spikes.maxWaveformCh1(ii),:,:),[2,3,1]),2),'k','linewidth',2),
        title(['Peak channel (',num2str(spikes.maxWaveformCh1(ii)),')']), xlabel('Samples'), ylabel('uV')
        
        subplot(2,3,4), hold on,
        plot(spikes.timeWaveform{ii},spikes.rawWaveform{ii}), title(['Raw waveform (',num2str(ii),'/',num2str(numel(unitsToProcess)),')']), xlabel('Time (ms)'), ylabel('uV')
        xlim([-0.8,0.8])
        subplot(2,3,5), hold on,
        plot(spikes.timeWaveform{ii},spikes.filtWaveform{ii}), title('Filtered waveform'), xlabel('Time (ms)'), ylabel('uV')
        xlim([-0.8,0.8])
        subplot(3,3,3), hold off
        plot(spikes.peakVoltage_sorted{ii},'.-b'), hold on
        plot(x,fitCoeffValues(1)*exp(-x/fitCoeffValues(2))+fitCoeffValues(3),'r'),
        title(['Spike amplitude (lambda=',num2str(spikes.peakVoltage_expFitLengthConstant(ii),2) ,')']), xlabel('Channels'), ylabel('uV'), xlim([0,nChannelFit])
        subplot(3,3,6), hold on
        plot(spikes.peakVoltage_sorted{ii}), title('Spike amplitude (all)'), xlabel('Channels'), ylabel('uV'), xlim([0,nChannelFit])
        subplot(3,3,9), hold off,
        histogram(spikes.peakVoltage_expFitLengthConstant,20), xlabel('Length constant')
    end
    clear wf wfF wf2 wfF2
    
    if ishandle(f)
        waitbar(i/length(unitsToProcess),f,['Waveforms: ',num2str(i),'/',num2str(length(unitsToProcess)),'. ', num2str(round(toc(timerVal)-t1)),' sec/unit, Duration: ', num2str(round(toc(timerVal)/60)), '/', num2str(round(toc(timerVal)/60/i*length(unitsToProcess))),' minutes']);
    else
        disp('Canceling waveform extraction...')
        clear rawWaveform rawWaveform_std filtWaveform filtWaveform_std
        clear rawData
        error('Waveform extraction canceled by user')
    end
end
% Plots
if ishandle(f)
    spikes.processinginfo.params.WaveformsSource = 'dat file';
    spikes.processinginfo.params.WaveformsFiltFreq = filtFreq;
    spikes.processinginfo.params.Waveforms_nPull = nPull;
    spikes.processinginfo.params.WaveformsWin_sec = wfWin_sec;
    spikes.processinginfo.params.WaveformsWinKeep = wfWinKeep;
    spikes.processinginfo.params.WaveformsFilterType = 'butter';
    clear rawWaveform rawWaveform_std filtWaveform filtWaveform_std
    clear rawData
%     waitbar(i/length(unitsToProcess),f,['Waveform extraction complete ',num2str(i),'/',num2str(length(unitsToProcess)),'.  ', num2str(round(toc(timerVal)/60)) ' minutes total']);
    disp(['Waveform extraction complete. Total duration: ' num2str(round(toc(timerVal)/60)),' minutes'])
    if ishandle(fig1)
        set(fig1,'Name',['Waveform extraction complete for ' basename])
    end
    close(f)
end
if ishandle(fig1)
    fig1.Name = [basename, ': Waveform extraction complete. ',num2str(i),' cells processed.  ', num2str(round(toc(timerVal)/60)) ' minutes total'];
end
end