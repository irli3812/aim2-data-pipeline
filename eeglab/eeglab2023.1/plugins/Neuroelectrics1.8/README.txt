%---------------- Version 1.7
- 1.8: Bug fix: file not loaded when 255-lost-packet marker and others are present.
- 1.7: Added: compatibility with NEDF version 1.4
- 1.6: Bug fix: channel location information for EASY files with 8 channels not displayed. NEDF: Triggers with values higher than 255 not loaded.
- 1.5: Bug fix: if only 255-packet-lost markers present data is not loaded.
- 1.4: Bug fix: Markers greater than 255 not read in easy files
- 1.3: Bug fix: Markers not read on NEDF1.3
- 1.2: Bug fix: NEDF1.3 with only EEG not loaded
- 1.1: Added conversion from nV to uV.

%---------------- Installation

Unzip this file in the plugins folder of EEGlab. 

Or place the folder "NE_EEGLAB_NIC_Plugin" in the plugins folder of EEGlab.

Attention!!: xml4mat must be inside the folder "NE_EEGLAB_NIC_Plugin" if you want to load NEDF files, otherwise you wont be able to load them. 

%-----------------Data Units

The data from NEDF and .Easy files is in nV, however the plugin already converts the data to uV.

%-----------------Locations advice

There is no location files available for Enobio8.

For Enobio20 there are 19 locations by default. The location of the EXT electrode has to be added manually in the .locs file, located in the locations folder. 
By default is set near the Cz electrode. 

