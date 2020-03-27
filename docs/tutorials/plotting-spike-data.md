---
layout: default
title: Plotting spike data
parent: Tutorials
nav_order: 6
---
# Tutorial on plotting spike raster data in the Cell Explorer
{: .no_toc}
This tutorial will show you how to generate raster plots using spike data. The spike data is not saved with the metrics and will be loaded separately. Events or manipulation files can also be loaded separately allowing you to generate two-dimensional rasters and PSTH raster plots. Any events or manipulation files located in the basepath will be detected in the pipeline and PSTHs will be generated. Events and manipulation files are similar in content, but only manipulation intervals are excluded in the pipeline by default. 



## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Show spike raster data in the Cell Explorer
The Cell Explorer can show spike raster data using the `sessionName.spikes.cellinfo.mat` and related structures (`sessionName.*.events.mat` and `sessionName.*.manipulation.mat`). See the [file definitions here]({{"/datastructure/data-structure-and-format/"|absolute_url}}).

1. Launch the Cell Explorer
2. Select `Spikes`-> `Spike data menu` from the top menu (keyboard shortcut: `ctrl+a`). 
3. The spike data will be loaded and below dialog will be shown in the Cell Explorer.
![](https://buzsakilab.com/wp/wp-content/uploads/2019/11/Cell-Explorer-spike-dialog.png)
4. Now, if the listed spike plotting options are sufficient. Press OK to close the dialog.
5. This will add the spike plotting options to the display settings dropdowns .
![](https://buzsakilab.com/wp/wp-content/uploads/2020/03/plotOptionsWithSpikes_2.png)
7. Select one of the spike plot option to display it. This will generate a raster plot similar to the image below.
![](https://buzsakilab.com/wp/wp-content/uploads/2020/03/spikes_time_amplitude-01.png)
8. If there are no spiking data available for the current session or the selected cell, the plot will be empty. This is also the case for datasets without specific events files for plots with event aligned PSTH raster plots. 

### Create and modify spike plots in the Cell Explorer
1. From the spike data dialog you can add, edit and delete spike plots. To add a new press the `add plot` button (to modify an exinsting plot, select one of the listed plots and click the `edit plot` button).
2. Below dialog will be shown allowing you to create a custom spike plot defined by the parameters displayed.
![](https://buzsakilab.com/wp/wp-content/uploads/2020/03/ModifySpikePlot.png)
3. The dialog can be separated into 5 sections. 1. Plot title, 2. x,y,state data, 3. axis labels, 4. filter, and 5. events.
    1. __PLot nane:__ Start by defining the name of the plot. This must fulfull the requirement of being a valid variable name.
    2. __x, y and state data:__ Next, define the fields to plot from the `spikes` struct. The x, y and a state vector can be chosen (state allows you to color-group your data. See the second rater example at the bottom of this page). 
    As an example, lets say you want to plot the spike amplitude across time (shown in the example above). In the x-data selection column, select times. In the y-data column, select amplitudes.
    3. __axis labels :__ Provide labels (e.g. Time (s) and Amplitude as x and y labels) and press OK. This will create a new plot looking like the raster example above.
    4. __filter :__ You can also define a data field to use as a filter. E.g. amplitude or speed. Select the field you want to use a filter, define the filter type (options: equal to, less than, greater than) and the threshold-value for the filter.
    5. __events :__ You can also create PSTH-rasters using separate event data. Define the type of the event (options: events, manipulations, states files), the name of the events, .e.g. ripples (e.g. `sessionName.ripples.events.mat`)), and the duration of the PSTH window (time before/after alignment in seconds). Next, define how to align the events (options: by onset, offset, center or peak). Each option must be available in the events files to be plotable, e.g. peak and offset, or be determined from other fields, e.g. center (which can be determined from the start and stop times of intervals). Using the event checkboxes you can select to display the average response and/or the raster, together with trial-wise curves. Below figure shows a PSTH for a opto-stimulated interneuron with 1200 trials and a stimulation window of 0.5sec. 
    ![](https://buzsakilab.com/wp/wp-content/uploads/2020/03/PSTH-raster-01.png)

### Predefine spike plots
You can predefine custom plots that are loaded automatically in the Cell Explorer every time. Custom spike plots are located in the folder `+customSpikesPlots/`. There is a `spikes_template.m` file available in the folder to get you started:
```m
function spikePlot = spikes_template
% This is a example template for creating your own custom spike raster plots
%
% OUTPUT
% spikePlot: a struct containing all settings

% Spikes struct parameter
spikePlot.x = 'pos_linearized';             % x data
spikePlot.y = 'theta_phase';                % y data
spikePlot.x_label = 'Position (cm)';        % x label
spikePlot.y_label = 'Theta phase';          % y label
spikePlot.state = '';                       % state data [ideally integer]
spikePlot.filter = 'speed';                 % any data used as filter
spikePlot.filterType = 'greater than';      % [none, equal to, less than, greater than]
spikePlot.filterValue = 20;                 % filter value

% Event related parameters (if applicable)
spikePlot.event = '';
spikePlot.eventType = 'events';             % [events,manipulation,states]
spikePlot.eventAlignment = 'peak';          % [onset, offset, center, peak] alignment of the PSTH
spikePlot.eventSorting = 'amplitude';       % [none, time, amplitude, duration] Trial soorting metric
spikePlot.eventSecBefore = 0.2;             % in seconds
spikePlot.eventSecAfter = 0.2;              % in seconds
spikePlot.plotRaster = 0;                   % [binary] show raster
spikePlot.plotAverage = 0;                  % [binary] show average response
spikePlot.plotAmplitude = 0;                % [binary] show amplitude for each event on a separate y-axis plot
spikePlot.plotDuration = 0;                 % [binary] show event duration for each event on a separate y-axis plot
spikePlot.plotCount = 0;                    % [binary] show spike count for each event on a separate y-axis plot
end
```

### Raster plot examples
Below figure shows three raster plot examples for an interneuron in CA1: 1. Theta phase vs linear position, 2. trial number vs position, colored according to 4 states and 3. spike amplitude (from KiloSort) vs time.
![Rasters](https://buzsakilab.com/wp/wp-content/uploads/2019/12/spikeRaster.png)