/*
 Image Quilting, Clay Heaton, 2015.
 
 This sketch provides an example implementation of the image quilting 
 algorithm described by Alexei Efros and William Freeman in their 
 oft-cited paper from 2001.
 
 From one or two original images (that should be similar, if using two),
 the algorithm "quilts" together samples from those images, seeking the 
 overlap seams between samples that minimizes the color differences. 
 Given the appropriate input image, the effect is that this can create 
 larger images, of arbitrary size, that do not look like they were 
 assembled by tiling the original image. 
 
 The A* algorithm is used to find the lowest-cost seam in overlap
 areas, vs. Dijkstra's, as described in the original paper. This
 works because we insert dummy "start" and "end" nodes in the graph
 constructed from overlapping pixels, then prune them away when we
 have found the minimal path between them.
 */

import java.util.PriorityQueue;

int i = 0;
// Set to true if you want to see debug information 
boolean debug = true;

// Declare test images - they are loaded in setup()
PImage fabric1;
PImage fabric2;

// Textures to use for the run of the sketch
// ASSIGN THEM BELOW!!!!! in the setup() function below (Processing requirement)
PImage texture1;
PImage texture2;

// % chance that a pixel will be drawn from texture1 vs. texture2
float texture1Chance = 0.8;

int sampleSize       = 64; // Side length of samples taken from original source
int overlapFactor    = 3;  // 6 for 1/6th of the sample size. 8 for 1/8th, etc.
int sampleOverlap    = sampleSize / overlapFactor; // Don't change this.

// How similar do the overlapping sections need to be?
// Low error tolerance, such as 0.15, means there can only be 15% of the max error
// represented in the overlap region of the samples.
// Typical ranges are 0.1 - 0.3, but they vary.
float overlapErrorTolerance = 0.2;

// Error Calculations - don't change these
int maxError      = int(sq(255) + sq(255) + sq(255)) * sampleSize * sampleOverlap; // num pixels * max error per pixel
int maxErrorValue = int(maxError * overlapErrorTolerance);

// Used to support debugging
ArrayList<PVector> debugLines;

// Background color defaults to black.
color bgColor = color(0, 0, 0);

// Needed to cover the canvas; don't change.
int columns, rows;

// Counters for tracking position; don't change.
int column, row;
int xOffset, yOffset, offsetAmount;

// For tracking progress; don't change.
boolean complete      = false;
boolean grabbedFinal  = false;

// Keep the final image; don't change.
PImage finalImage;

Table table;
String [] images = {
  "output_swatches/2000.1.0312.jpg", "output_swatches/1996.2.0343.JPG", "output_swatches/KNA 1639.jpg", "output_swatches/KNA 647.JPG", "output_swatches/KNA 6570.jpg", "output_swatches/KNA 644.JPG", "output_swatches/KNA 648.JPG", "output_swatches/KNA 3158.jpg", "output_swatches/2000.1.0314.jpg", "output_swatches/KNA 643.JPG", "output_swatches/KNA 645.JPG", "output_swatches/KNA 1640.JPG", "output_swatches/KNA 1641.JPG", "output_swatches/KNA 1959.jpg", "output_swatches/KNA 939.JPG", "output_swatches/2003.1.0279az.jpg", "output_swatches/KNA 2218(1-4)1.jpg", "output_swatches/KNA 649.JPG", "output_swatches/KNA 786.jpg", "output_swatches/KNA 1998.JPG", "output_swatches/2003.1.0278.JPG", "output_swatches/KNA 2218(1-4)2.jpg", "output_swatches/KNA 846.jpg", "output_swatches/KNA 787.JPG", "output_swatches/KNA 1997.jpg", "output_swatches/KNA 793.jpg", "output_swatches/KNA 2218(1-4)3.jpg", "output_swatches/KNA 2218(1-4)4.jpg", "output_swatches/5996_11.jpg", "output_swatches/1992.1.0077.JPG", "output_swatches/2013.2.0083.jpg", "output_swatches/KNA 6508.jpg", "output_swatches/KNA 6681.JPG", "output_swatches/40063.jpg", "output_swatches/1999.1.0491.jpg", "output_swatches/KNA 1781.jpg", "output_swatches/7271_15.jpg", "output_swatches/1994.1.0069.jpg", "output_swatches/2007.1.0054(1-25).jpg", "output_swatches/2006.2.0001.JPG", "output_swatches/2006.2.0004.JPG", "output_swatches/2006.2.0007.JPG", "output_swatches/2006.2.0346.JPG", "output_swatches/2006.2.0406.JPG", "output_swatches/2006.2.0002.JPG", "output_swatches/2006.2.0005.JPG", "output_swatches/2006.2.0008.JPG", "output_swatches/2006.2.0374.JPG", "output_swatches/2006.2.0003.JPG", "output_swatches/2006.2.0006.JPG", "output_swatches/2006.2.0073.JPG", "output_swatches/2006.2.0407.JPG", "output_swatches/KNA 608.jpg", "output_swatches/KNA 609.jpg", "output_swatches/KNA 1960.jpg", "output_swatches/KNA 1682.jpg", "output_swatches/KNA 804.jpg", "output_swatches/KNA 1686.JPG", "output_swatches/KNA 610.jpg", "output_swatches/KNA 802.jpg", "output_swatches/KNA 1683.JPG", "output_swatches/KNA 805.jpg", "output_swatches/KNA 1687.jpg", "output_swatches/KNA 32.jpg", "output_swatches/KNA 803.jpg", "output_swatches/KNA 646.JPG", "output_swatches/KNA 1685.jpg", "output_swatches/KNA 1933.jpg", "output_swatches/KNA 457.jpg", "output_swatches/KNA 1684.JPG", "output_swatches/2002.1.0384-387(A).jpg", "output_swatches/2002.1.0384-387(A).jpg", "output_swatches/KNA 1775.jpg", "output_swatches/KNA 466.jpg", "output_swatches/KNA 6131.jpg", "output_swatches/2002.1.0384-387(A).jpg", "output_swatches/KNA 8849(1-2)1.jpg", "output_swatches/KNA 616.jpg", "output_swatches/KNA 788.jpg", "output_swatches/KNA 6132.jpg", "output_swatches/2002.1.0384-387(A).jpg", "output_swatches/KNA 8849(1-2)2.jpg", "output_swatches/KNA 2629.jpg", "output_swatches/KNA 1978.JPG", "output_swatches/KNA 1976(1-2).jpg", "output_swatches/2013.1.0545.jpg", "output_swatches/2008.1.0162.JPG", "output_swatches/2014.2.0118.jpg", "output_swatches/KNA 1974.JPG", "output_swatches/KNA 1977.JPG", "output_swatches/2008.1.0163.JPG", "output_swatches/2014.2.0122.jpg", "output_swatches/KNA 1975.JPG", "output_swatches/2014.1.0124.jpg", "output_swatches/2008.1.0164.JPG", "output_swatches/2519_10.jpg", "output_swatches/KNA 6768.JPG", "output_swatches/2000.1.0678(4).jpg", "output_swatches/KNA 458.jpg", "output_swatches/1989.1.0003.JPG", "output_swatches/KNA 2113.jpg", "output_swatches/20388.jpg", "output_swatches/2010.1.0453.jpg", "output_swatches/39918.jpg", "output_swatches/KNA 9334.jpg", "output_swatches/2010.1.0456a.jpg", "output_swatches/2010.7.0270(1-2)1.jpg", "output_swatches/KNA 4455.jpg", "output_swatches/2010.1.0454.jpg", "output_swatches/KNA 9335.jpg", "output_swatches/1991.2.0283(1-12).jpg", "output_swatches/2010.1.0457.jpg", "output_swatches/KNA 3616.jpg", "output_swatches/KNA 9333.jpg", "output_swatches/2010.1.0455.jpg", "output_swatches/KNA 9336.jpg", "output_swatches/KNA 3487.jpg", "output_swatches/2003.2.0130(1-6).jpg", "output_swatches/1988.2.0314b.jpg", "output_swatches//1993.2.0318.jpg", "output_swatches/2010.2.0461.jpg", "output_swatches/2010.1.0459.jpg", "output_swatches/2013.2.0370.jpg", "output_swatches/2010.2.0462.jpg", "output_swatches/2010.1.0458.jpg", "output_swatches/2010.2.0464.jpg", "output_swatches/2010.2.0465.jpg", "output_swatches/2013.2.0391.jpg", "output_swatches/1996.2.0307.jpg", "output_swatches/2010.2.0463a.jpg", "output_swatches/2010.1.0460.jpg", "output_swatches/2013.2.0368.jpg", "output_swatches/39965.jpg", "output_swatches/2013.2.0372.jpg", "output_swatches/2013.2.0389.jpg", "output_swatches/KNA 5424.JPG", "output_swatches/39972.jpg", "output_swatches/2013.2.0379.jpg", "output_swatches/2013.2.0387.jpg", "output_swatches/2013.2.0373.jpg", "output_swatches/2013.2.0377.jpg", "output_swatches/7226_30.jpg", "output_swatches/2013.2.0388.jpg", "output_swatches/KNA 5321.jpg", "output_swatches/39964.jpg", "output_swatches/2013.2.0378(1-21).jpg", "output_swatches/KNA 465.jpg", "output_swatches/KNA 1999.jpg", "output_swatches/KNA 4591.jpg", "output_swatches/KNA 1779.jpg", "output_swatches/2003.1.0614(1-4).jpg", "output_swatches/KNA 1782.jpg", "output_swatches/KNA 4589.jpg", "output_swatches/2000.1.0710.jpg", "output_swatches/2003.1.0614(1-4).jpg", "output_swatches/KNA 339.JPG", "output_swatches/KNB 120.JPG", "output_swatches/KNA 1778.jpg", "output_swatches/KNA 1780.jpg", "output_swatches/KNA 2103.JPG", "output_swatches/KNB 40.jpg", "output_swatches/KNA 2888.jpg", "output_swatches/KNA 2890.jpg", "output_swatches/KNA 2891.jpg", "output_swatches/KNA 2892.jpg", "output_swatches/KNA 2889.jpg", "output_swatches/KNA 2893.jpg", "output_swatches//KNA 1771a.jpg", "output_swatches/KNA 1783.jpg", "output_swatches/KNA 342.jpg", "output_swatches/KNA 1986.JPG", "output_swatches/KNA 1704.JPG", "output_swatches/KNA 1707.JPG", "output_swatches/KNA 21.jpg", "output_swatches/KNA 2219.jpg", "output_swatches/KNA 1987.JPG", "output_swatches/KNA 1708.JPG", "output_swatches/KNA 341.jpg", "output_swatches/KNA 1985.JPG", "output_swatches/KNA 1703.JPG", "output_swatches/KNA 1706.JPG", "output_swatches/KNA 1709.jpg", "output_swatches/1989.2.0322.jpg", "output_swatches/KNA 1660.jpg", "output_swatches/KNA 815.jpg", "output_swatches/KNA 1677.jpg", "output_swatches/KNA 794.JPG", "output_swatches/KNA 6215.jpg", "output_swatches/KNA 607.jpg", "output_swatches/KNA 1675.jpg", "output_swatches/KNA 1678.jpg", "output_swatches/KNA 1680.JPG", "output_swatches/KNA 814.jpg", "output_swatches/KNA 1676.jpg", "output_swatches/KNA 1679.jpg", "output_swatches/KNA 1681.JPG", "output_swatches/KNA 686.jpg", "output_swatches/1987.2.0123-124a.jpg", "output_swatches/KNA 611.jpg", "output_swatches/KNA 1712.JPG", "output_swatches/KNA 1715.JPG", "output_swatches/KNA 1718.JPG", "output_swatches/KNA 612.jpg", "output_swatches/KNA 1713.JPG", "output_swatches/KNA 1716.JPG", "output_swatches/KNA 1719.JPG", "output_swatches/KNA 615.jpg", "output_swatches/KNA 613.jpg", "output_swatches/KNA 1714.JPG", "output_swatches/KNA 1717.JPG", "output_swatches/KNA 1720.JPG", "output_swatches/KNA 1721.JPG", "output_swatches/KNA 1724.JPG", "output_swatches/KNA 2110.jpg", "output_swatches/1996.2.0344(1-2)1.jpg", "output_swatches/KNA 1722.JPG", "output_swatches/KNA 1725.JPG", "output_swatches/KNA 2945.JPG", "output_swatches/1996.2.0345(1-2)1.jpg", "output_swatches/KNA 1723.JPG", "output_swatches/KNA 1726.JPG", "output_swatches/KNA 2946.JPG", "output_swatches/1996.2.0346.JPG", "output_swatches/KNA 7911.JPG", "output_swatches/1989.2.0203.JPG", "output_swatches/1988.1.0043.JPG", "output_swatches/1995.1.0225.jpg", "output_swatches/1995.1.0224.JPG", "output_swatches/1989.2.0204.JPG", "output_swatches/1993.1.0018.JPG", "output_swatches/1995.1.0222.JPG", "output_swatches/1995.1.0223.jpg", "output_swatches/1989.2.0325(1-3).jpg", "output_swatches/KNB 117.jpg", "output_swatches/KNA 1819.jpg", "output_swatches/TYP 04736.jpg", "output_swatches/1988.1.0276_20.jpg", "output_swatches/1988.1.0276_26.jpg", "output_swatches/1988.1.0276_25.jpg", "output_swatches/KNB 116.jpg", "output_swatches/TYP 04737.jpg", "output_swatches/1988.1.0276_21.jpg", "output_swatches/1988.1.0276_23.jpg", "output_swatches/1988.1.0276_27.jpg", "output_swatches/TYP 04735.jpg", "output_swatches/TYP 04738.jpg", "output_swatches/1988.1.0276_22.jpg", "output_swatches/1988.1.0276_24.jpg", "output_swatches/1988.1.0276_28.jpg", "output_swatches/1988.1.0276_36.jpg", "output_swatches/1988.1.0276_29.jpg", "output_swatches/1988.1.0276_37.jpg", "output_swatches/1988.1.0276_39.jpg", "output_swatches/1988.1.0276_61.02.jpg", "output_swatches/1988.1.0276_30.jpg", "output_swatches/1988.1.0276_35.jpg", "output_swatches/1988.1.0276_31.jpg", "output_swatches/1988.1.0276_64.02.jpg", "output_swatches/1988.1.0276_60.jpg", "output_swatches/1988.1.0276_32.04.jpg", "output_swatches/1988.1.0276_34.jpg", "output_swatches/1988.1.0276_33.jpg", "output_swatches/1988.1.0276_42.01.jpg", "output_swatches/1988.1.0276_64.01.jpg", "output_swatches/1988.1.0276_55.jpg", "output_swatches/1988.1.0276_40.02.jpg", "output_swatches/1988.1.0276_61.01.jpg", "output_swatches/1988.1.0276_54.jpg", "output_swatches/1988.1.0276_56.jpg", "output_swatches/1988.1.0276_49.01.jpg", "output_swatches/1988.1.0276_40.01.jpg", "output_swatches/1988.1.0276_67.jpg", "output_swatches/1988.1.0276_50.03.jpg", "output_swatches/1988.1.0276_69.jpg", "output_swatches/1988.1.0276_65.jpg", "output_swatches/1988.1.0276_59.jpg", "output_swatches/1988.1.0276_66.jpg", "output_swatches/1988.1.0276_57.jpg", "output_swatches/1988.1.0276_58.01.jpg", "output_swatches/1988.1.0276_58.02.jpg", "output_swatches/1988.1.0276_68.jpg", "output_swatches/1988.1.0276_48.02.jpg", "output_swatches/1988.1.0276_62.01.jpg", "output_swatches/1988.1.0276_48.01.jpg", "output_swatches/1988.1.0276_48.03.jpg", "output_swatches/1988.1.0276_41.01.jpg", "output_swatches/1988.1.0276_51.jpg", "output_swatches/1988.1.0276_41.02.jpg", "output_swatches/1988.1.0276_50.01.jpg", "output_swatches/1988.1.0276_48.04.jpg", "output_swatches/1988.1.0276_46.01.jpg", "output_swatches/1988.1.0276_52.jpg", "output_swatches/1988.1.0276_53.jpg", "output_swatches/1988.1.0276_62.03.jpg", "output_swatches/1988.1.0276_50.02.jpg", "output_swatches/1988.1.0276_45.01.jpg", "output_swatches/1988.1.0276_43.03.jpg", "output_swatches/1988.1.0276_43.04.jpg", "output_swatches/1988.1.0276_47.01.jpg", "output_swatches/1988.1.0276_62.02.jpg", "output_swatches/1988.1.0276_45.02.jpg", "output_swatches/1988.1.0276_43.02.jpg", "output_swatches/1988.1.0276_63.jpg", "output_swatches/1988.1.0276_44.01.jpg", "output_swatches/1988.1.0276_47.02.jpg", "output_swatches/1988.1.0276_49.02.jpg", "output_swatches/1988.1.0276_43.01.jpg", "output_swatches/1988.1.0276_44.02.jpg", "output_swatches/1988.1.0276_42.02.jpg", "output_swatches/1988.1.0276_42.03.jpg", "output_swatches/1988.1.0276_42.06.jpg", "output_swatches/1988.1.0276_42.09.jpg", "output_swatches/1988.1.0276_46.03.jpg", "output_swatches/1988.1.0276_46.06.jpg", "output_swatches/1988.1.0276_42.04.jpg", "output_swatches/1988.1.0276_42.07.jpg", "output_swatches/1988.1.0276_42.10.jpg", "output_swatches/1988.1.0276_46.04.jpg", "output_swatches/1988.1.0276_38.jpg", "output_swatches/1988.1.0276_42.05.jpg", "output_swatches/1988.1.0276_42.08.jpg", "output_swatches/1988.1.0276_46.02.jpg", "output_swatches/1988.1.0276_46.05.jpg", "output_swatches/39306.jpg", "output_swatches/KNA 888.jpg", "output_swatches/KNA 585.jpg", "output_swatches/KNA 588.jpg", "output_swatches/KNA 889.jpg", "output_swatches/KNA 586.jpg", "output_swatches/KNA 891.jpg", "output_swatches/KNA 890.jpg", "output_swatches/KNA 587.jpg", "output_swatches/KNA 2171.JPG", "output_swatches/KNA 2170.JPG", "output_swatches/KNA 604.jpg", "output_swatches/KNA 916a.jpg", "output_swatches/2003.1.0001.JPG", "output_swatches/KNA 618.JPG", "output_swatches/KNA 603.jpg", "output_swatches/KNA 605.jpg", "output_swatches/KNA 917.jpg", "output_swatches/2011.2.0017.jpg", "output_swatches/KNA 617.JPG", "output_swatches/KNA 602.jpg", "output_swatches/KNA 3253.jpg", "output_swatches/KNA 3254.jpg", "output_swatches/2014.2.0213(1-5).jpg", "output_swatches/1995.2.0265.jpg", "output_swatches/KNA 1694.jpg", "output_swatches/1995.2.0266.jpg", "output_swatches/2014.2.0211(1-7).jpg", "output_swatches/2014.2.0214(1-7).jpg", "output_swatches/KNA 782.JPG", "output_swatches/KNA 1695.jpg", "output_swatches/2014.2.0218(1-6).jpg", "output_swatches/2014.2.0212(1-8).jpg", "output_swatches/2014.2.0215.jpg", "output_swatches/KNA 783.jpg", "output_swatches/KNA 1696.jpg", "output_swatches/2014.2.0216(1-4).jpg", "output_swatches/2014.2.0217(1-4).jpg", "output_swatches/2014.2.0001.jpg", "output_swatches/KNA 3644.jpg", "output_swatches/KNA 4590.jpg", "output_swatches/2014.2.0002.jpg", "output_swatches/1994.1.0171.JPG", "output_swatches/KNA 918.jpg", "output_swatches/KNA 6658.JPG", "output_swatches/10286_3.jpg", "output_swatches/1992.2.1134(1-2)1.jpg", "output_swatches/KNA 6659.jpg", "output_swatches/KNB 111.jpg", "output_swatches/KNB 115.jpg", "output_swatches/1997.2.0358.JPG", "output_swatches/1461_13.jpg", "output_swatches/KNA 6166(1-2)2.jpg", "output_swatches/KNB 113.jpg", "output_swatches/KNB 112.jpg", "output_swatches/KNB319.jpg", "output_swatches/KNA 3288.jpg", "output_swatches/1991.1.0056.JPG", "output_swatches/KNB 114.jpg", "output_swatches/2003.1.0255(1-7).jpg", "output_swatches/2005.2.0234(1-12).JPG", "output_swatches/KNA 3429a.jpg", "output_swatches/KNA 2160.jpg", "output_swatches/2003.1.0089.jpg", "output_swatches/KNA 1784.jpg", "output_swatches/KNA 2161.jpg", "output_swatches/2003.1.0088.jpg", "output_swatches/2006.2.0587. black.jpg", "output_swatches/150_3.jpg", "output_swatches/KNA 2162.jpg", "output_swatches/1989.2.0205.jpg", "output_swatches/2005.2.0375.JPG", "output_swatches/2005.2.0378.JPG", "output_swatches/1994.1.0086.JPG", "output_swatches/2005.2.0377.JPG", "output_swatches/2003.1.0592.JPG", "output_swatches/2005.2.0374.JPG", "output_swatches/2005.2.0373.JPG", "output_swatches/2003.1.0593.JPG", "output_swatches/2003.1.0594.JPG", "output_swatches/2003.1.0597.JPG", "output_swatches/22273.jpg", "output_swatches/2003.1.0595.JPG", "output_swatches/2005.2.0372.JPG", "output_swatches/2002.1.0325.JPG", "output_swatches/2003.1.0596.JPG", "output_swatches/2005.2.0376.JPG"
};

String [] colors = {
  "output_colors/2000.1.0312.jpg", "output_colors/1996.2.0343.JPG", "output_colors/KNA 1639.jpg", "output_colors/KNA 647.JPG", "output_colors/KNA 6570.jpg", "output_colors/KNA 644.JPG", "output_colors/KNA 648.JPG", "output_colors/KNA 3158.jpg", "output_colors/2000.1.0314.jpg", "output_colors/KNA 643.JPG", "output_colors/KNA 645.JPG", "output_colors/KNA 1640.JPG", "output_colors/KNA 1641.JPG", "output_colors/KNA 1959.jpg", "output_colors/KNA 939.JPG", "output_colors/2003.1.0279az.jpg", "output_colors/KNA 2218(1-4)1.jpg", "output_colors/KNA 649.JPG", "output_colors/KNA 786.jpg", "output_colors/KNA 1998.JPG", "output_colors/2003.1.0278.JPG", "output_colors/KNA 2218(1-4)2.jpg", "output_colors/KNA 846.jpg", "output_colors/KNA 787.JPG", "output_colors/KNA 1997.jpg", "output_colors/KNA 793.jpg", "output_colors/KNA 2218(1-4)3.jpg", "output_colors/KNA 2218(1-4)4.jpg", "output_colors/5996_11.jpg", "output_colors/1992.1.0077.JPG", "output_colors/2013.2.0083.jpg", "output_colors/KNA 6508.jpg", "output_colors/KNA 6681.JPG", "output_colors/40063.jpg", "output_colors/1999.1.0491.jpg", "output_colors/KNA 1781.jpg", "output_colors/7271_15.jpg", "output_colors/1994.1.0069.jpg", "output_colors/2007.1.0054(1-25).jpg", "output_colors/2006.2.0001.JPG", "output_colors/2006.2.0004.JPG", "output_colors/2006.2.0007.JPG", "output_colors/2006.2.0346.JPG", "output_colors/2006.2.0406.JPG", "output_colors/2006.2.0002.JPG", "output_colors/2006.2.0005.JPG", "output_colors/2006.2.0008.JPG", "output_colors/2006.2.0374.JPG", "output_colors/2006.2.0003.JPG", "output_colors/2006.2.0006.JPG", "output_colors/2006.2.0073.JPG", "output_colors/2006.2.0407.JPG", "output_colors/KNA 608.jpg", "output_colors/KNA 609.jpg", "output_colors/KNA 1960.jpg", "output_colors/KNA 1682.jpg", "output_colors/KNA 804.jpg", "output_colors/KNA 1686.JPG", "output_colors/KNA 610.jpg", "output_colors/KNA 802.jpg", "output_colors/KNA 1683.JPG", "output_colors/KNA 805.jpg", "output_colors/KNA 1687.jpg", "output_colors/KNA 32.jpg", "output_colors/KNA 803.jpg", "output_colors/KNA 646.JPG", "output_colors/KNA 1685.jpg", "output_colors/KNA 1933.jpg", "output_colors/KNA 457.jpg", "output_colors/KNA 1684.JPG", "output_colors/2002.1.0384-387(A).jpg", "output_colors/2002.1.0384-387(A).jpg", "output_colors/KNA 1775.jpg", "output_colors/KNA 466.jpg", "output_colors/KNA 6131.jpg", "output_colors/2002.1.0384-387(A).jpg", "output_colors/KNA 8849(1-2)1.jpg", "output_colors/KNA 616.jpg", "output_colors/KNA 788.jpg", "output_colors/KNA 6132.jpg", "output_colors/2002.1.0384-387(A).jpg", "output_colors/KNA 8849(1-2)2.jpg", "output_colors/KNA 2629.jpg", "output_colors/KNA 1978.JPG", "output_colors/KNA 1976(1-2).jpg", "output_colors/2013.1.0545.jpg", "output_colors/2008.1.0162.JPG", "output_colors/2014.2.0118.jpg", "output_colors/KNA 1974.JPG", "output_colors/KNA 1977.JPG", "output_colors/2008.1.0163.JPG", "output_colors/2014.2.0122.jpg", "output_colors/KNA 1975.JPG", "output_colors/2014.1.0124.jpg", "output_colors/2008.1.0164.JPG", "output_colors/2519_10.jpg", "output_colors/KNA 6768.JPG", "output_colors/2000.1.0678(4).jpg", "output_colors/KNA 458.jpg", "output_colors/1989.1.0003.JPG", "output_colors/KNA 2113.jpg", "output_colors/20388.jpg", "output_colors/2010.1.0453.jpg", "output_colors/39918.jpg", "output_colors/KNA 9334.jpg", "output_colors/2010.1.0456a.jpg", "output_colors/2010.7.0270(1-2)1.jpg", "output_colors/KNA 4455.jpg", "output_colors/2010.1.0454.jpg", "output_colors/KNA 9335.jpg", "output_colors/1991.2.0283(1-12).jpg", "output_colors/2010.1.0457.jpg", "output_colors/KNA 3616.jpg", "output_colors/KNA 9333.jpg", "output_colors/2010.1.0455.jpg", "output_colors/KNA 9336.jpg", "output_colors/KNA 3487.jpg", "output_colors//2003.2.0130(1-6).jpg", "output_colors/1988.2.0314b.jpg", "output_colors//1993.2.0318.jpg", "output_colors/2010.2.0461.jpg", "output_colors/2010.1.0459.jpg", "output_colors/2013.2.0370.jpg", "output_colors/2010.2.0462.jpg", "output_colors/2010.1.0458.jpg", "output_colors/2010.2.0464.jpg", "output_colors/2010.2.0465.jpg", "output_colors/2013.2.0391.jpg", "output_colors/1996.2.0307.jpg", "output_colors/2010.2.0463a.jpg", "output_colors/2010.1.0460.jpg", "output_colors/2013.2.0368.jpg", "output_colors/39965.jpg", "output_colors/2013.2.0372.jpg", "output_colors/2013.2.0389.jpg", "output_colors/KNA 5424.JPG", "output_colors/39972.jpg", "output_colors/2013.2.0379.jpg", "output_colors/2013.2.0387.jpg", "output_colors/2013.2.0373.jpg", "output_colors/2013.2.0377.jpg", "output_colors/7226_30.jpg", "output_colors/2013.2.0388.jpg", "output_colors/KNA 5321.jpg", "output_colors/39964.jpg", "output_colors/2013.2.0378(1-21).jpg", "output_colors/KNA 465.jpg", "output_colors/KNA 1999.jpg", "output_colors/KNA 4591.jpg", "output_colors/KNA 1779.jpg", "output_colors/2003.1.0614(1-4).jpg", "output_colors/KNA 1782.jpg", "output_colors/KNA 4589.jpg", "output_colors/2000.1.0710.jpg", "output_colors/2003.1.0614(1-4).jpg", "output_colors/KNA 339.JPG", "output_colors/KNB 120.JPG", "output_colors/KNA 1778.jpg", "output_colors/KNA 1780.jpg", "output_colors/KNA 2103.JPG", "output_colors/KNB 40.jpg", "output_colors/KNA 2888.jpg", "output_colors/KNA 2890.jpg", "output_colors/KNA 2891.jpg", "output_colors/KNA 2892.jpg", "output_colors/KNA 2889.jpg", "output_colors/KNA 2893.jpg", "output_colors//KNA 1771a.jpg", "output_colors/KNA 1783.jpg", "output_colors/KNA 342.jpg", "output_colors/KNA 1986.JPG", "output_colors/KNA 1704.JPG", "output_colors/KNA 1707.JPG", "output_colors/KNA 21.jpg", "output_colors/KNA 2219.jpg", "output_colors/KNA 1987.JPG", "output_colors/KNA 1708.JPG", "output_colors/KNA 341.jpg", "output_colors/KNA 1985.JPG", "output_colors/KNA 1703.JPG", "output_colors/KNA 1706.JPG", "output_colors/KNA 1709.jpg", "output_colors/1989.2.0322.jpg", "output_colors/KNA 1660.jpg", "output_colors/KNA 815.jpg", "output_colors/KNA 1677.jpg", "output_colors/KNA 794.JPG", "output_colors/KNA 6215.jpg", "output_colors/KNA 607.jpg", "output_colors/KNA 1675.jpg", "output_colors/KNA 1678.jpg", "output_colors/KNA 1680.JPG", "output_colors/KNA 814.jpg", "output_colors/KNA 1676.jpg", "output_colors/KNA 1679.jpg", "output_colors/KNA 1681.JPG", "output_colors/KNA 686.jpg", "output_colors/1987.2.0123-124a.jpg", "output_colors/KNA 611.jpg", "output_colors/KNA 1712.JPG", "output_colors/KNA 1715.JPG", "output_colors/KNA 1718.JPG", "output_colors/KNA 612.jpg", "output_colors/KNA 1713.JPG", "output_colors/KNA 1716.JPG", "output_colors/KNA 1719.JPG", "output_colors/KNA 615.jpg", "output_colors/KNA 613.jpg", "output_colors/KNA 1714.JPG", "output_colors/KNA 1717.JPG", "output_colors/KNA 1720.JPG", "output_colors/KNA 1721.JPG", "output_colors/KNA 1724.JPG", "output_colors/KNA 2110.jpg", "output_colors/1996.2.0344(1-2)1.jpg", "output_colors/KNA 1722.JPG", "output_colors/KNA 1725.JPG", "output_colors/KNA 2945.JPG", "output_colors/1996.2.0345(1-2)1.jpg", "output_colors/KNA 1723.JPG", "output_colors/KNA 1726.JPG", "output_colors/KNA 2946.JPG", "output_colors/1996.2.0346.JPG", "output_colors/KNA 7911.JPG", "output_colors/1989.2.0203.JPG", "output_colors/1988.1.0043.JPG", "output_colors/1995.1.0225.jpg", "output_colors/1995.1.0224.JPG", "output_colors/1989.2.0204.JPG", "output_colors/1993.1.0018.JPG", "output_colors/1995.1.0222.JPG", "output_colors/1995.1.0223.jpg", "output_colors/1989.2.0325(1-3).jpg", "output_colors/KNB 117.jpg", "output_colors/KNA 1819.jpg", "output_colors/TYP 04736.jpg", "output_colors/1988.1.0276_20.jpg", "output_colors/1988.1.0276_26.jpg", "output_colors/1988.1.0276_25.jpg", "output_colors/KNB 116.jpg", "output_colors/TYP 04737.jpg", "output_colors/1988.1.0276_21.jpg", "output_colors/1988.1.0276_23.jpg", "output_colors/1988.1.0276_27.jpg", "output_colors/TYP 04735.jpg", "output_colors/TYP 04738.jpg", "output_colors/1988.1.0276_22.jpg", "output_colors/1988.1.0276_24.jpg", "output_colors/1988.1.0276_28.jpg", "output_colors/1988.1.0276_36.jpg", "output_colors/1988.1.0276_29.jpg", "output_colors/1988.1.0276_37.jpg", "output_colors/1988.1.0276_39.jpg", "output_colors/1988.1.0276_61.02.jpg", "output_colors/1988.1.0276_30.jpg", "output_colors/1988.1.0276_35.jpg", "output_colors/1988.1.0276_31.jpg", "output_colors/1988.1.0276_64.02.jpg", "output_colors/1988.1.0276_60.jpg", "output_colors/1988.1.0276_32.04.jpg", "output_colors/1988.1.0276_34.jpg", "output_colors/1988.1.0276_33.jpg", "output_colors/1988.1.0276_42.01.jpg", "output_colors/1988.1.0276_64.01.jpg", "output_colors/1988.1.0276_55.jpg", "output_colors/1988.1.0276_40.02.jpg", "output_colors/1988.1.0276_61.01.jpg", "output_colors/1988.1.0276_54.jpg", "output_colors/1988.1.0276_56.jpg", "output_colors/1988.1.0276_49.01.jpg", "output_colors/1988.1.0276_40.01.jpg", "output_colors/1988.1.0276_67.jpg", "output_colors/1988.1.0276_50.03.jpg", "output_colors/1988.1.0276_69.jpg", "output_colors/1988.1.0276_65.jpg", "output_colors/1988.1.0276_59.jpg", "output_colors/1988.1.0276_66.jpg", "output_colors/1988.1.0276_57.jpg", "output_colors/1988.1.0276_58.01.jpg", "output_colors/1988.1.0276_58.02.jpg", "output_colors/1988.1.0276_68.jpg", "output_colors/1988.1.0276_48.02.jpg", "output_colors/1988.1.0276_62.01.jpg", "output_colors/1988.1.0276_48.01.jpg", "output_colors/1988.1.0276_48.03.jpg", "output_colors/1988.1.0276_41.01.jpg", "output_colors/1988.1.0276_51.jpg", "output_colors/1988.1.0276_41.02.jpg", "output_colors/1988.1.0276_50.01.jpg", "output_colors/1988.1.0276_48.04.jpg", "output_colors/1988.1.0276_46.01.jpg", "output_colors/1988.1.0276_52.jpg", "output_colors/1988.1.0276_53.jpg", "output_colors/1988.1.0276_62.03.jpg", "output_colors/1988.1.0276_50.02.jpg", "output_colors/1988.1.0276_45.01.jpg", "output_colors/1988.1.0276_43.03.jpg", "output_colors/1988.1.0276_43.04.jpg", "output_colors/1988.1.0276_47.01.jpg", "output_colors/1988.1.0276_62.02.jpg", "output_colors/1988.1.0276_45.02.jpg", "output_colors/1988.1.0276_43.02.jpg", "output_colors/1988.1.0276_63.jpg", "output_colors/1988.1.0276_44.01.jpg", "output_colors/1988.1.0276_47.02.jpg", "output_colors/1988.1.0276_49.02.jpg", "output_colors/1988.1.0276_43.01.jpg", "output_colors/1988.1.0276_44.02.jpg", "output_colors/1988.1.0276_42.02.jpg", "output_colors/1988.1.0276_42.03.jpg", "output_colors/1988.1.0276_42.06.jpg", "output_colors/1988.1.0276_42.09.jpg", "output_colors/1988.1.0276_46.03.jpg", "output_colors/1988.1.0276_46.06.jpg", "output_colors/1988.1.0276_42.04.jpg", "output_colors/1988.1.0276_42.07.jpg", "output_colors/1988.1.0276_42.10.jpg", "output_colors/1988.1.0276_46.04.jpg", "output_colors/1988.1.0276_38.jpg", "output_colors/1988.1.0276_42.05.jpg", "output_colors/1988.1.0276_42.08.jpg", "output_colors/1988.1.0276_46.02.jpg", "output_colors/1988.1.0276_46.05.jpg", "output_colors/39306.jpg", "output_colors/KNA 888.jpg", "output_colors/KNA 585.jpg", "output_colors/KNA 588.jpg", "output_colors/KNA 889.jpg", "output_colors/KNA 586.jpg", "output_colors/KNA 891.jpg", "output_colors/KNA 890.jpg", "output_colors/KNA 587.jpg", "output_colors/KNA 2171.JPG", "output_colors/KNA 2170.JPG", "output_colors/KNA 604.jpg", "output_colors/KNA 916a.jpg", "output_colors/2003.1.0001.JPG", "output_colors/KNA 618.JPG", "output_colors/KNA 603.jpg", "output_colors/KNA 605.jpg", "output_colors/KNA 917.jpg", "output_colors/2011.2.0017.jpg", "output_colors/KNA 617.JPG", "output_colors/KNA 602.jpg", "output_colors/KNA 3253.jpg", "output_colors/KNA 3254.jpg", "output_colors/2014.2.0213(1-5).jpg", "output_colors/1995.2.0265.jpg", "output_colors/KNA 1694.jpg", "output_colors/1995.2.0266.jpg", "output_colors/2014.2.0211(1-7).jpg", "output_colors/2014.2.0214(1-7).jpg", "output_colors/KNA 782.JPG", "output_colors/KNA 1695.jpg", "output_colors/2014.2.0218(1-6).jpg", "output_colors/2014.2.0212(1-8).jpg", "output_colors/2014.2.0215.jpg", "output_colors/KNA 783.jpg", "output_colors/KNA 1696.jpg", "output_colors/2014.2.0216(1-4).jpg", "output_colors/2014.2.0217(1-4).jpg", "output_colors/2014.2.0001.jpg", "output_colors/KNA 3644.jpg", "output_colors/KNA 4590.jpg", "output_colors/2014.2.0002.jpg", "output_colors/1994.1.0171.JPG", "output_colors/KNA 918.jpg", "output_colors/KNA 6658.JPG", "output_colors/10286_3.jpg", "output_colors/1992.2.1134(1-2)1.jpg", "output_colors/KNA 6659.jpg", "output_colors/KNB 111.jpg", "output_colors/KNB 115.jpg", "output_colors/1997.2.0358.JPG", "output_colors/1461_13.jpg", "output_colors/KNA 6166(1-2)2.jpg", "output_colors/KNB 113.jpg", "output_colors/KNB 112.jpg", "output_colors/KNB319.jpg", "output_colors/KNA 3288.jpg", "output_colors/1991.1.0056.JPG", "output_colors/KNB 114.jpg", "output_colors/2003.1.0255(1-7).jpg", "output_colors/2005.2.0234(1-12).JPG", "output_colors/KNA 3429a.jpg", "output_colors/KNA 2160.jpg", "output_colors/2003.1.0089.jpg", "output_colors/KNA 1784.jpg", "output_colors/KNA 2161.jpg", "output_colors/2003.1.0088.jpg", "output_colors/2006.2.0587. black.jpg", "output_colors/150_3.jpg", "output_colors/KNA 2162.jpg", "output_colors/1989.2.0205.jpg", "output_colors/2005.2.0375.JPG", "output_colors/2005.2.0378.JPG", "output_colors/1994.1.0086.JPG", "output_colors/2005.2.0377.JPG", "output_colors/2003.1.0592.JPG", "output_colors/2005.2.0374.JPG", "output_colors/2005.2.0373.JPG", "output_colors/2003.1.0593.JPG", "output_colors/2003.1.0594.JPG", "output_colors/2003.1.0597.JPG", "output_colors/22273.jpg", "output_colors/2003.1.0595.JPG", "output_colors/2005.2.0372.JPG", "output_colors/2002.1.0325.JPG", "output_colors/2003.1.0596.JPG", "output_colors/2005.2.0376.JPG"
};

void setup() {
  size(500, 500);
  background(bgColor);
  fabric1 = loadImage(images[411]);
  fabric2 = loadImage(colors[411]);
  //fabric2 = loadImage(images[407]);
  texture1 = fabric1;
  texture2 = fabric2;

  columns = 1 + width  / (sampleSize - sampleOverlap);
  rows    = 1 + height / (sampleSize - sampleOverlap);

  // Counters
  column  = 0;
  row     = 0;

  offsetAmount = sampleSize - sampleOverlap;
  debugLines   = new ArrayList<PVector>();
}

void draw() {

  ////////////////////////////////////////////////
  ////// Stuff to do when the image is complete //
  ////////////////////////////////////////////////

  if (complete == true && grabbedFinal == false) {
    frameRate(5);
    finalImage = createImage(width, height, RGB);
    finalImage = get(0, 0, width, height);
    grabbedFinal = true;
  }

  ////////////////////////////////////////////////
  ////// Stuff to do to create the image /////////
  ////////////////////////////////////////////////

  if (!complete) {

    xOffset = column * offsetAmount;
    yOffset = row    * offsetAmount; 

    Sample s;

    if (random(1) > (1-texture1Chance)) {
      s = new Sample(texture1);
    } else {
      s = new Sample(texture2);
    }

    if (column == 0 && row == 0) {
      // Initial tile doesn't have to check seams
      PImage i = s.sample;
      image(i, xOffset, yOffset);
    } else {
      s.placeTile(xOffset, yOffset);
    }

    // Tracking the "for" loop abstracted out of draw()
    column += 1;
    if (column == columns) {
      column = 0;
      row += 1;
    }

    // We are done when row == rows
    if (row == rows) {
      complete = true; 
      println("Finished!");
    }
  }  
}

void mousePressed() {
  save("imgs/tile404.jpg");
}

//void keyPressed() {
//  i++;
//  redraw();
//}