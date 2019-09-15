// ImageJ macro to measure fluorescent indicator expression in bacterial cells
// Kate Bowers (undergraduate), Levin Lab, Tufts University 2019
// Requires ImageJ version 1.52p (June 2019) or above

// Updated July 25th 2019 - adding customizable filter min/max, 
//         contrast value logs, filter out particles smaller than min

// GET VALID PARENT SAVE DIRECTORY
parentDir = "";
exists = false;
while (!exists) {
	Dialog.create("Choose Directory");
	Dialog.addString("Full path to directory for saved results: ", parentDir);
	Dialog.addNumber("Minimum particle size (square μm)", 0.5);
	Dialog.addNumber("Maximum particle size (square μm)", 5);
	Dialog.show();
	parentDir = Dialog.getString();
	min = Dialog.getNumber();
	max = Dialog.getNumber();

	if (!endsWith(parentDir, File.separator)) { // clean up
		parentDir += File.separator;
	}
	exists = File.isDirectory(parentDir); // check that it exists
}

// MAKE DIRECTORY FOR THIS IMAGE COLLECTION
exampleTitle = getTitle();
title_lif_index = indexOf(exampleTitle, ".lif");
collectionTitle = substring(exampleTitle, 0, title_lif_index);
collectionTitle = replace(collectionTitle, " ", "_");
collectionDir = parentDir + collectionTitle + File.separator;
File.makeDirectory(collectionDir);

// MAKE FILE TO LOG BRIGHTNESS/CONTRAST MEASUREMENTS PER IMAGE
bc_log= File.open(collectionDir + "contrast_log.txt");
print(bc_log, collectionTitle + " Brightness/Contrast log");
print(bc_log, "Particle size min: " + min);
print(bc_log, "Particle size max: " + max);

// RUN ON EACH OPEN IMAGE
windows = getList("image.titles");
num_windows = windows.length;
run("Set Measurements...", "area mean perimeter shape skewness redirect=None decimal=3");
while (num_windows != 0) {
	imageTitle = processPhase();
	num_ch = numChannels();
	thresh_mask("singlecell");
	thresh_mask("multicell");
	processChannel("C2-", collectionDir, num_ch, "singlecell");
	processChannel("C2-", collectionDir, num_ch, "multicell");
	if (num_ch == 2) {
		processChannel("C3-", collectionDir, num_ch, "singlecell");
		processChannel("C3-", collectionDir, num_ch, "multicell");
	}
	close("*-"+imageTitle);
	close("singlecell mask");
	close("multicell mask");
	num_windows--;
}

/* FUNCTION DEFINITIONS */

function processPhase() {
	// SPLIT CHANNELS
	imageTitle=getTitle();
	run("Split Channels"); 

	// ADJUST CONTRAST (USER INPUT)
	selectWindow("C1-"+imageTitle);
	run("Brightness/Contrast...");
	selectWindow("C1-"+imageTitle);
	setMinAndMax(6981, 11173);
	waitForUser("Is this contrast ok? Please adjust and click Set.");
	bmin = 0;
	bmax = 0;
	getMinAndMax(bmin, bmax);
	run("Apply LUT");
	print(bc_log, imageTitle);
	print(bc_log, "Minimum: " + bmin + "  Maximum: " + bmax);
	setAutoThreshold("Default dark");
	return imageTitle;
}

function thresh_mask(type) {
	// SET THRESHOLD, MAKE MASKS
	selectWindow("C1-"+imageTitle);
	run("Threshold...");
	setAutoThreshold("Default");
	if (type == "singlecell") {
		run("Analyze Particles...", "size="+min+"-"+max+" show=Masks include slice");
	} else if (type == "multicell") {
		// look for particles > max sq microns, save separately (clumps, blobs, etc)
		run("Analyze Particles...", "size="+max+"-Infinity show=Masks include slice");
	}
	rename(type + " mask");
}

function processChannel(which, dir, num, type) {
	// MAKE AND PLACE MASK
	selectWindow(type + " mask");
	run("Create Selection");
	selectWindow(which + imageTitle); // "which" is C2/C3
	run("Restore Selection");
	
	// MAKE ROIs
	roiManager("Add");
	if(selectionType() == 9) { // composite selection
		roiManager("Split");
		roiManager("Select", 0);
		roiManager("Delete");
	} else { // single selection filter - sometimes a glitch makes a false ROI
		if (type == "multicell") {
			if (getValue("Area") < max) { // false ROI - "multicell" area < 5
				roiManager("Delete");
				closeAll();
				return;
			}
		} else if (type == "singlecell") { // false ROI - "singlecell" area > 5
			if (getValue("Area") > max) {
				roiManager("Delete");
				closeAll();
				return;
			}
		}
	}
	
	// MEASURE ROIs
	roiManager("measure");
	selectWindow("Results");
	Table.sort("Area");

	// FILTER OUT TINY PARTICLES
	while (Table.get("Area", 0) < min) {
        Table.deleteRows(0,0);
	}

	// SAVE DATA
	title = imageTitle;
	lif_index = indexOf(title, ".lif") + 7;
	new_title = substring(title, lif_index);
    new_title = replace(new_title, " ", "_");

	if (num == 2) {
		if (which == "C2-") {
			new_title = new_title + "-ThT";
		} else if (which == "C3-") {
			new_title = new_title + "-RGECO";
		}
	}
	new_title = new_title + "-" + type;
    saveAs("results", collectionDir+new_title+".csv");

	// CLEAR CHANNEL INFO
	roiManager("Delete");
	closeAll();
}

function closeAll() {
	// CLOSE ALL WINDOWS FROM THIS IMAGE SESSION
	
	close("Mask of*");
	close("B&C");
	close("ROI Manager");
	close("Threshold");
	close("Results");
}

function numChannels() {
	// FIND HOW MANY FLUORESCENT CHANNELS THE IMAGE PRODUCED (1 or 2)
	num = 0;
	titles = getList("image.titles");
	for (i = 0; i < titles.length; i++) {
		if (startsWith(titles[i], "C3-")) {
			return 2;
		} else if (startsWith(titles[i],"C2-")) {
			num++;
		}
	}
	return num;
}
