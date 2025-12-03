//define input image
input="/Users/mas/Downloads/Images/ECM analysis test/MMP2k0060_vkgGFP_ecadmK2_14.5hAPF_2025_06_25__17_37_35-test.tif";
//number of slices = nos, change for each image
nos=40;
//define number of timepoints, change for each image
timepoints=2;
//define output folder
outputDir="/Users/mas/Downloads/Images/ECM analysis test";
folder = getDirectory(outputDir); 

for (i=1; i<timepoints+1; i++) {
run("Bio-Formats Importer", "open=[" + input + "] color_mode=Composite rois_import=[ROI manager] specify_range view=Hyperstack stack_order=XYCZT z_begin=1 z_end=[nos] z_step=1 t_begin=[i] t_end=[i] t_step=1");
title_full=getTitle();
dotIndex = indexOf(title_full, ".tif" );
title=substring(title_full, 0, dotIndex );
folder2 = folder + File.separator + title + "-" + i; 
File.makeDirectory(folder2);

//save individual timepoint as tiff
saveAs("Tiff", folder2 + "/" + title + "-" + i);
wait(1000);
selectImage(title + "-" + i + ".tif");
new_title=getTitle();

//create binary image
run("Gaussian Blur 3D...", "x=2 y=2 z=2");
setAutoThreshold("IsoData dark stack");
setOption("BlackBackground", false);
run("Convert to Mask", "method=IsoData background=Dark create");
run("Erode", "stack");
run("Dilate", "stack");
selectWindow(new_title);
close();
selectWindow("MASK_" + new_title);
saveAs("Tiff", folder2 + "/" + "MASK_" + new_title);

//run Morphological Segmentation
run("Morphological Segmentation");
wait(10000);
selectWindow("Morphological Segmentation");
//setTool("multipoint");
call("inra.ijpb.plugins.MorphologicalSegmentation.setInputImageType", "object");
call("inra.ijpb.plugins.MorphologicalSegmentation.setGradientRadius", "2");
call("inra.ijpb.plugins.MorphologicalSegmentation.setGradientType", "Morphological");
call("inra.ijpb.plugins.MorphologicalSegmentation.segment", "tolerance=10.0", "calculateDams=true", "connectivity=26");
call("inra.ijpb.plugins.MorphologicalSegmentation.setDisplayFormat", "Catchment basins");
wait(250000);
call("inra.ijpb.plugins.MorphologicalSegmentation.createResultImage");
//waitForUser("If no segmentation image has been made, manually create image and then press OK");
selectWindow("Morphological Segmentation");
close();
run("Remove Largest Label");
run("Label Size Filtering", "operation=Greater_Than size=150");
saveAs("Tiff", folder2 + "/" + new_title + "segmentation");
close("\\Others");
run("Analyze Regions 3D", "volume surface_area sphericity bounding_box centroid equivalent_ellipsoid surface_area_method=[Crofton (13 dirs.)] euler_connectivity=6");
saveAs("Results", folder2 + "/" + new_title + ".csv");
close("*");
close(new_title + ".csv");
}
