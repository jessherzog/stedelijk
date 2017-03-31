// tie loop with concept, frame what you're doing - why this museum?
// acknowledge source, be computational in your approach
// get 'swatches' with ImageMagick
// 12 iterations of processing the images.
// sort by dates, colors, or come up with one generative process (creates 100 kinds)
// describe the process: indentify the txtiles, curating them, 


var CSVdata;
var imgsrc;
var dates;
var img;
var posX, posY = 0;

function preload(){
	// load csv:
	CSVdata = loadTable("data/dates2.csv", "csv", "header");
	// csv headers: image, last_name, first_name, title, date
	
}

function setup(){
	
	noCanvas();
	
	imgsrc = CSVdata.getColumn("image");
	for(var i=0; i < imgsrc.length; i++){
		
		createImg("data/" + imgsrc[i]);
	}
	
	// image processing function 

}


function draw(){
	// draw images to canvas
	
		
}