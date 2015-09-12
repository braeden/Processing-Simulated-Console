//Credit: https://github.com/westdew

//Slightly modified for my liking

// Processing Console
// Usage:
//   void console() {
//     // CODE
//   }
//   
// Use in place of setup and draw when creating a console based application. The console function is run in its own thread.
//
// Console Functions:
//   puts(output) // Write the contents of the string output to the screen.
//
//   input = gets() // Read from the keyboard into the string input until the enter key is pressed.
// 
// Supports paste with CTRL+V and copy (last displayed line) with CTRL+C

void console() {
  puts("What is your name?");
  String name = gets();
  println(name);
  puts("Hello, " + name + ".");
}












































// GLOBALS
ArrayList<String> consoleLog = new ArrayList<String>();
String keyBuffer = "";

int fontSize = 20;
String fontFamily = "Courier New";
int textHeight = fontSize + 4;

float barX() { return(width - 15); }
float barY = 5;
float barWidth = 8;
float fullBarHeight() { return(height - 10); }
float contentBarHeight; // Calculated

boolean copied = false;
int copiedPopup = 0;

// MAIN FUNCTIONS
void puts(String output) {
  consoleLog.add(0, output);
}

void cls() {
  consoleLog.clear();
}

String gets() {
  recording = true;
  while(recording) { delay(1); }
  
  String input = keyBuffer;
  keyBuffer = "";
  
  consoleLog.add(0, "=> " + input);    
  return(input);
}

// HELPER FUNCTIONS

boolean mouseOnContentBar() {
  boolean mouseInContentBarWidth = (mouseX > barX() && mouseX < barX() + barWidth);
  boolean mouseInContentBarHeight = (mouseY > barY + (fullBarHeight() - contentBarHeight) - scrollY && mouseY < barY + fullBarHeight() - scrollY);
  return (mouseInContentBarWidth && mouseInContentBarHeight);
}

float scrollY = 0;
void scroll(int delY) {
  scrollY -= delY;
  
  if (scrollY < 0) {
    scrollY = 0;
  } else if (scrollY > fullBarHeight() - contentBarHeight) {
    scrollY = fullBarHeight() - contentBarHeight;
  }
}

// EVENTS
boolean recording = false;
boolean controlMode = false;
void keyPressed() {
  if (keyCode == 17) {
    controlMode = true;
  }
  
  if (controlMode) {
    if (keyCode == 67) {
      cp.copyString(consoleLog.get(0));
    } else if (keyCode == 86) {
      keyBuffer += cp.pasteString();
    }
  } else {
    if (key == ENTER || key == RETURN) {
      recording = false;
    }
    
    if (recording) {
      if (key == BACKSPACE) {
        if (keyBuffer.length() > 0) {
          keyBuffer = keyBuffer.substring(0, keyBuffer.length()-1);
        }
      } else if (key >= ' ' && key <= '~') {
        keyBuffer += str(key);
      }
    }
  }
}

void keyReleased() {
  if (keyCode == 17) {
    controlMode = false;
  }
}

int clickY = -1;
void mousePressed() {  
  if (mouseOnContentBar()) {
    cursor(HAND);
    clickY = mouseY;
  } 
}

void mouseDragged() {   
  if (clickY > 0) {
    int delY = mouseY - clickY;
    
    scroll(delY);
    
    clickY = mouseY;  
  }
}

void mouseReleased() {
  cursor(ARROW);
  clickY = -1;
}

void mouseWheel(MouseEvent event) {
  float dir = event.getCount();
  
  scroll(int(dir * 30)); 
}

// SETUP
void setup() {
  size(800, 600);
  surface.setResizable(true);
  
  frameRate(60);  
  noSmooth();
  
  PFont fixedWidthFont = createFont(fontFamily, fontSize);
  textFont(fixedWidthFont);
  
  thread("console");
}


// DRAW
void drawScrollbar() {  
  // Full Bar
  stroke(230);
  fill(230);  
  rect(barX(), barY, barWidth, fullBarHeight());
  
  // Content Bar
  stroke(180);
  fill(180);
  float contentHeight = textHeight/2 + consoleLog.size()*textHeight;
  contentBarHeight = (height / contentHeight) * fullBarHeight();
  rect(barX(), barY + (fullBarHeight() - contentBarHeight) - scrollY, barWidth, contentBarHeight);
}

int last_blink = 0;
String cursor = "";
void drawConsoleText() {
  fill(255);
  float contentHeight = textHeight/2 + consoleLog.size()*textHeight;
  float scrollOffset = scrollY / (fullBarHeight() - contentBarHeight) * (contentHeight - height);  
  int i = 0;
  
  if (recording) {    
    // Cursor
    if (last_blink + 500 < millis()) {      
      last_blink = millis();
      if (focused && cursor == "") {
        cursor = "█";
      } else  if (!focused && cursor == "") {
        cursor = "░";
      } else {
        cursor = "";
      }
    }
    // Input
    text("$> " + keyBuffer + cursor, 6, height + scrollOffset - textHeight/2 - textHeight*i++);
  }
    
  // Output
  for (String line : consoleLog) {    
    text(line, 6, height + scrollOffset - textHeight/2 - textHeight*i++);
  }
}
void draw() {
  background(0);  
  
  drawScrollbar();  
  textAlign(LEFT);
  drawConsoleText();
  
  if (copied) {
    textAlign(CENTER);
    text("Copied", width/2, height/2);
  }
  if (copiedPopup + 500 < millis()) {      
    copied = false;
  }
}

///////////////////////////////////////////////////////
// Clipboard class for Processing                    //
// by seltar, modified by adamohern                  //
// v 0115AO                                          //
// only works with programs. applets require signing //
///////////////////////////////////////////////////////

import java.awt.datatransfer.*;
import java.awt.Toolkit; 

ClipHelper cp = new ClipHelper();

// CLIPHELPER OBJECT CLASS:

class ClipHelper {
  Clipboard clipboard;
  
  ClipHelper() {
    getClipboard();  
  }
  
  void getClipboard () {
    // this is our simple thread that grabs the clipboard
    Thread clipThread = new Thread() {
      public void run() {
        clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
      }
    };
  
    // start the thread as a daemon thread and wait for it to die
    if (clipboard == null) {
      try {
        clipThread.setDaemon(true);
        clipThread.start();
        clipThread.join();
      }  
      catch (Exception e) {}
    }
  }
  
  void copyString (String data) {
    copyTransferableObject(new StringSelection(data));
    copied = true;
    copiedPopup = millis();
  }
  
  void copyTransferableObject (Transferable contents) {
    getClipboard();
    clipboard.setContents(contents, null);
  }
  
  String pasteString () {
    String data = null;
    try {
      data = (String)pasteObject(DataFlavor.stringFlavor);
    }  
    catch (Exception e) {
      System.err.println("Error getting String from clipboard: " + e);
    }
    return data;
  }
  
  Object pasteObject (DataFlavor flavor)  
  throws UnsupportedFlavorException, IOException
  {
    Object obj = null;
    getClipboard();
    
    Transferable content = clipboard.getContents(null);
    if (content != null)
      obj = content.getTransferData(flavor);
    
    return obj;
  }
}