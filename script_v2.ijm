/*
 * Description: Macro to quantify extra-cellular matrix degradation
 * Author: Sarah Ma (sarah.ma at crick.ac.uk), 2025
 */

var MIN_VOLUME = 150;
var FILTER_RADIUS = 2;
var THRESH_METHOD = "IsoData";

macro "ECM_Quantification"{
	
	// Bio-Formats Macro Extensions can be used to obtain metadata from the image file before opening it
	run("Bio-Formats Macro Extensions");

	input=File.openDialog("Choose Input Image");
	Ext.setId(input);
	Ext.getSizeT(timepoints);
	Ext.getSizeZ(nos);
	
	outputParentDir = getDirectory("Choose Output Directory");

	print("Input File: " + input);
	print("Timepoints: " + timepoints);
	print("Z-Slices: " + nos);
	print("Output Directory: " + outputParentDir);

	setBatchMode(true);
	
	for (i=0; i<timepoints; i++) {
		print("Processing timepoint " + (i + 1) + " of " + timepoints);
		run("Bio-Formats Importer", "open=[" + input + "] specify_range t_begin=" + i + " t_end=" + i + " t_step=1");
		title_full=getTitle();
		title = File.getNameWithoutExtension(input);
		outputChildDir = outputParentDir + File.separator + title + "_T" + i; 
		File.makeDirectory(outputChildDir);
		
		//save individual timepoint as tiff
		outputFilePath = outputChildDir + "/" + title + "-" + i + ".tiff";
		print("Saving " + outputFilePath);
		saveAs(outputFilePath);
		outputFilename=File.getNameWithoutExtension(getTitle());
		
		//create binary image
		run("Gaussian Blur 3D...", "x=" + FILTER_RADIUS + " y=" + FILTER_RADIUS + " z="  + FILTER_RADIUS);
		run("Convert to Mask", "method=" + THRESH_METHOD + " background=Dark create");
		run("Erode", "stack");
		run("Dilate", "stack");
		outputFilePath = outputChildDir + File.separator() + outputFilename + "_mask.tiff";
		print("Saving " + outputFilePath);
		saveAs(outputFilePath);
		run("Connected Components Labeling", "connectivity=6 type=[16 bits]");
		run("Remove Largest Label");
		run("Label Size Filtering", "operation=Greater_Than size=" + MIN_VOLUME);
		outputFilePath = outputChildDir + File.separator() + outputFilename + "_segmentation.tiff";
		print("Saving " + outputFilePath);
		saveAs(outputFilePath);
		close("\\Others");
		run("Analyze Regions 3D", "volume surface_area sphericity bounding_box centroid equivalent_ellipsoid surface_area_method=[Crofton (13 dirs.)] euler_connectivity=6");
		outputFilePath = outputChildDir + File.separator() + outputFilename + ".csv";
		print("Saving " + outputFilePath);
		saveAs("Results", outputFilePath);
		close("*");
		close(outputFilename + ".csv");
	}
	
	setBatchMode(false);
	
	print("Done");
}