//Macro to generate Kymos from MT snaps and GFP streams.
//Chris Gell 28-11-2017
//Version 1

//macro to make kymos for gfp tirf data
//assumes 2 images are loaded and that 
//these are a stream and a mt.
//go to either and add lines to the 
//ROI manager. Then run the macro.

//to do the next one clear the ROI manager
//and close all open windows.
//load the next strem and snap.



// to add 
// have it work out which is the stream
// reduce thickness or transparency of the lines in the mt map
//name directory in an intelegent way - not wanted, not flexible.
//cope with multiple streams (of the same MT FOV)?



//see if any images are open.
if (nImages!=2) {
	//
	Dialog.create("");
	Dialog.addMessage("Too many or too few images open, open 2 images, the MTs and stream.");
	Dialog.show();
	exit; 
}



roiManager("show all with labels")

setBatchMode(true); 

//ask for an identifier for this analysis
expName=getString("Enter an indetifier for this experiment", "");




 //create an array with a list of open window names
 n = nImages; 
    list = newArray(n); 
    setBatchMode(true); 
    for (i=1; i<=n; i++) { 
        selectImage(i); 
        list[i-1] = getTitle; 
    } 
    //setBatchMode(false); 

// create a dialog to get the user to tell us which is which
title = "Choose MT image";
width=1024; height=1024;
Dialog.create("Choose MT image");
Dialog.addChoice("Type:", list);
Dialog.show();
mtImageName = Dialog.getChoice();




// create a dialog to get the user to tell us which is which
title = "Choose GFP image";
width=1024; height=1024;
Dialog.create("Choose GFP image");
Dialog.addChoice("Type:", list);
Dialog.show();

gfpImageName = Dialog.getChoice();

//print(gfpImageName);



//make the stack for the MT kymo
// "ConvertImageToStack"
//
// This macro expands a single image into a
// stack by duplicating the image a specified  
// number of times.

//get the number of frames in the stream
selectWindow(gfpImageName);
getDimensions(width, height, channels, slices, frames);

  n = frames;
  //print(n);

 selectWindow(mtImageName);
 //make a blurred mt image, a little better look for the kymos
 run("Gaussian Blur...", "sigma=1");
 

 
  
  run("Copy");
  for (i=0; i<n-1; i++) {
      run("Add Slice");
      run("Paste");
  }







n = roiManager("count");
  for (i=0; i<n; i++) {
      


//Make the GFp channel kymo
selectWindow(gfpImageName);
roiManager("select", i);
Roi.setStrokeWidth(3);
run("Multi Kymograph", "linewidth=3");
selectWindow("Kymograph");
rename("GFP - Kymograph" + (i + 1) +" "+expName);
run("Green");
run("Enhance Contrast", "saturated=0.35");

//Make the MT kymo
selectWindow(mtImageName);
roiManager("select", i);
Roi.setStrokeWidth(7);
run("Magenta");
run("Multi Kymograph", "linewidth=7");
selectWindow("Kymograph");
rename("MT - Kymograph" + i+1+" "+expName);
selectWindow("MT - Kymograph" + (i+1)+" "+expName);
run("Magenta");

//make the merged kymo
run("Merge Channels...", "c2=[GFP - Kymograph"+ (i+1)+" "+expName+"] c6=[MT - Kymograph"+ (i+1)+ " "+expName+"] create");
selectWindow("Composite");
rename("MT - GFP - Kymograph" + (i+1)+" "+expName);


  }// end of ROI loop


//make record image
selectWindow(mtImageName);
run("Duplicate...", " ");
rename("MTs");
run("Invert");
run("Grays");
run("Enhance Contrast", "saturated=0.35");
roiManager("Show All");



//close orignals
selectWindow(mtImageName);
close(mtImageName);
selectWindow(gfpImageName);
close(gfpImageName);

//save everything
dir = getDirectory("Choose a Directory");
//dirTemp = getDirectory("Choose a Directory");
//File.makeDirectory(dir+expName); 
//newDir=dir + "/"+expName+"/";
newDir=dir;



ids=newArray(nImages); 
for (i=0;i<nImages;i++) { 
        selectImage(i+1); 
        title = getTitle; 
        //print(title); 
        ids[i]=getImageID; 

        saveAs("tiff", newDir + expName + title + " " + "MT-" + mtImageName+ "Stream-"+gfpImageName); 
}

 roiManager("deselect"); 
 roiManager("save", newDir +expName+" "+gfpImageName+".zip") 

 //ask user if wants kymo and mt 'map' saving as png.
//getBoolean("Save PNGs of everything?");
 if (getBoolean("Save PNGs of everything?")) {
 
ids=newArray(nImages); 

for (i=0;i<nImages;i++) { 
        selectImage(i+1); 
        title = getTitle; 
        //print(title); 
        ids[i]=getImageID; 
		//run("Flatten");
        //saveAs("png", dir+title+" "+gfpImageName); 
        saveAs("png", newDir+expName+title); 
}
} 




setBatchMode(false); 

//End of code

