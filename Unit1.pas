//**************************************************************************************************
// Propagation des ondes
//
// Auteur: neodelphi
//         neodelphi@hotmail.com
//
// Date: 31/10/2005
//
// Description: Ce source met en application les �quations de propagations des ondes sur un plan
//              d'eau. La physique est adapt� pour le programme et certains calculs sont simplifi�s
//              dans le seul but d'obtenir un rendu "r�aliste".
//
//              Dans un premier temps le programme calcule la propagation des ondes sur le plan
//              d'eau, puis un rendu avec pseudo-r�fraction d'une image en arri�re plan permet de
//              visualiser le r�sultat.
//
// Remarques:   Les fichiers arri�re plans sont dans le r�pertoire backgrounds\ et doivent �tre au
//              format bmp. Aucune contrainte n'est fix�e sur la taille des images, le rendu
//              duplique le motif si n�cessaire (voir checker.bmp).
//
//              Le programme g�re un mode de rendu basse qualit� pour les machines plus lentes.
//**************************************************************************************************
unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Math, XPMan, Menus;

type


  // Donn� d'un �l�ment sur la grille du plan d'eau
  // Correspond � la hauteur et vitesse de l'eau en un point
  TWave = record
    height: double;
    speed : double;
  end;


  TMainForm = class(TForm)
    Panel1: TPanel;
    Image: TImage;
    XPManifest1: TXPManifest;
    GroupBox1: TGroupBox;
    CheckBox1: TCheckBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    ScrollBar1: TScrollBar;
    Label2: TLabel;
    ScrollBar2: TScrollBar;
    Label3: TLabel;
    ScrollBar3: TScrollBar;
    Label5: TLabel;
    ScrollBar4: TScrollBar;
    Label6: TLabel;
    ComboBox1: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure ScrollBar2Change(Sender: TObject);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ScrollBar3Change(Sender: TObject);
    procedure ImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ScrollBar4Change(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
  private
    { D�clarations priv�es }
  public
    // M�thodes d'initialisation
    procedure init();
    procedure initBitmap();
    procedure initBackgroundsNames();
    procedure initBackgroundBitmap(fileName: string);
    procedure initWavesArray();
    procedure initWavesData();
    procedure initBackgroundLines();
    procedure initBitmapLines();

    // M�thodes de simulation
    procedure simul();
    procedure simulEdges();
    procedure ripple(centerX, centerY, radius: integer; height: double);    

    procedure render();
    procedure idle(sender: TObject; var done: boolean);
    procedure fps();
  end;

var
  MainForm: TMainForm;

  // R�pertoire de travail de l'application (initialis� dans la m�thode init) 
  rep: string;

  // Dimensions du bitmap
  // La dimensions de la grille pour l'eau est (bitmapWidth+1)x(bitmapHeight+1)
  bitmapWidth    : integer;
  bitmapHeight   : integer;
  backgroundLines: array of PByteArray;
  bitmapLines    : array of PByteArray;
  halfResolution : boolean;

  // Bitmap de l'image de fond (charg� dans la m�thode initBackgroundBitmap) et liste des fichiers
  // image
  backgroundBitmap: TBitmap;
  backgroundsNames: TStringList;

  // Grille des vagues (initialis� dans initWavesArray)
  waves: array of array of TWave;

  // Parm�tres de rendu et d'animation:
  lightIntensity: double; // Intensit� de l'effet de lumi�re
  depth         : double; // Profondeur de l'eau pour la pseudo-r�fraction
  viscosity     : double; // pseudo-viscosit� pour l'animation
  wavesSpeed    : double; // param�tre pour la vitesse des vagues (doit valoir au minimum 2.0)

  // Etat souris
  leftDown: boolean;

  // Affichage du nombre d'image par secondes
  lastT   : integer;
  fpsCount: integer;


implementation

{$R *.dfm}


{*
 * idle
 *
 * M�thode appel�e d�s que le programme est libre, c'est a dire beaucoup de fois par seconde !
 * Cette m�thode permet de r�aliser une boucle d'animation tout en laissant la possibilit� �
 * l'utilisateur de clicker sur les composants de la fen�tre.
 *}
procedure TMainForm.idle(sender: TObject; var done: boolean);
begin
  // Animation seulement si la case est coch�es !
  if checkBox1.checked then
    begin
    // Simulation
    simulEdges();
    simul();

    // Rendu et affichage du fps
    render();
    fps();
    end;

  done := false;
end;


{*
 * fps
 *
 * Affiche toutes les secondes le nombre d'images calcul�es lors de la derni�re seconde.
 *}
procedure TMainForm.fps();
var
  t: integer;
begin
  // R�cup�ration du temps actuel en ms
  t := getTickCount;

  // Si �a fait plus d'une seconde que l'on a calcul� le fps, on le recalcul
  if t-lastT>=1000 then
    begin
    caption :='Water Effect ('+ inttostr(fpsCount) + ' FPS)';
    lastT := t;
    // Remise � zero du compteur d'images
    fpsCount := 0;
    end
    else
    begin
    // ... sinon on incr�ment le compteur d'images
    inc(fpsCount);
    end;
end;


{*
 * init
 *}
procedure TMainForm.init();
begin
  // Extraction du r�pertoire racine
  rep := ExtractFilePath(application.exeName);

  // Faible r�solution pour les machines lentes ?
  // La faible r�solution utilise le stretching de l'image et ne calcul q'un quart de l'image
  if MessageDlg('Render in high quality?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
    halfResolution := false;
    bitmapWidth  := Image.width;
    bitmapHeight := Image.height;
    end
    else
    begin
    halfResolution := true;
    Image.Stretch := true;
    bitmapWidth  := Image.width div 2;
    bitmapHeight := Image.height div 2;
    end;

  lightIntensity := scrollBar1.Position;
  wavesSpeed     := scrollBar4.Position;
  viscosity      := scrollBar3.Position/100;
  depth          := ScrollBar2.Position/10.0;

  // FPS
  fpsCount := 0;
  lastT    := getTickCount();

  // Initialisation du bitmap
  initBitmap();
  initBitmapLines();

  // Initialisation du bitmap d'arri�re plan
  initBackgroundsNames();
  initBackGroundBitmap(backgroundsNames[0]);
  initBackGroundLines();

  // Initialisation des vagues
  initWavesArray();
  initWavesData();

  Application.OnIdle := idle;
end;


{*
 * initWavesArray
 *}
procedure TMainForm.initWavesArray();
var
  x: integer;
begin
  // Dimensionnement de l'array
  setLength(waves, bitmapWidth+1);
  for x:=0 to bitmapWidth do
    setLength(waves[x], bitmapHeight+1);
end;


{*
 * initWavesData
 *}
procedure TMainForm.initWavesData();
var
  x: integer;
  y: integer;
begin
  // Modifier cette m�thode pour avoir une configuration de vagues initiale
  for x:=0 to bitmapWidth do
  for y:=0 to bitmapHeight do
    begin
    waves[x, y].height := 0.0;
    waves[x, y].speed := 0.0;
    end;
end;


{*
 * initBitmap
 *
 * Initialisation du bitmap
 *}
procedure TMainForm.initBitmap();
var
  bit: TBitmap;
begin
  bit := TBitmap.create();
  bit.width := bitmapWidth;
  bit.height := bitmapHeight;
  bit.PixelFormat := pf24bit;
  Image.Picture.Assign(bit);
  bit.free();
end;


{*
 * initBackgroundsNames
 *
 * Etabli la liste des arri�res plans au format bmp
 *}
procedure TMainForm.initBackgroundsNames();
var
  searchRec: TSearchRec;
begin
  backgroundsNames := TStringList.Create();

  // Liste les images du r�pertoire backgrounds\
  if findFirst('.\backgrounds\*', faAnyFile, searchRec) = 0 then
    begin
    repeat
      if extractFileExt(searchRec.Name)='.bmp' then
        backgroundsNames.Add(searchRec.Name);
    until findNext(searchRec)<>0;
    end;

  // Ajout de la liste des fichiers bmp dans la comboBox
  ComboBox1.Items.AddStrings(backgroundsNames);
end;


{*
 * initBackgroundBitmap
 *}
procedure TMainForm.initBackgroundBitmap(fileName: string);
begin
  // Si le bitmap n'existe pas d�j� (initialisation) on le cr�
  if not assigned(backgroundBitmap) then backgroundBitmap := TBitmap.Create();
  try
    // Chargement du bitmap depuis le fichier
    backgroundBitmap.LoadFromFile(rep+'backgrounds\'+fileName);
    // Passage en mode RVB 24 bit pour le travail des pixels
    backgroundBitmap.PixelFormat := pf24bit;
  except
    // La c'est pas bon signe !
    showMessage('Error: couldn''t load background image');
  end;
end;


{*
 * initBackgroundLines
 *
 * Construit le tableau des pointeurs sur les lignes du background
 *}
procedure TMainForm.initBackgroundLines();
var
  i: integer;
begin
  setLength(backgroundLines, backgroundBitmap.Height);

  for i:=0 to backgroundBitmap.Height-1 do
    begin
    backgroundLines[i] := backgroundBitmap.ScanLine[i];
    end;
end;


{*
 * initBitmapLines
 *
 * Construit le tableau des pointeurs sur les lignes du bitmap
 *}
procedure TMainForm.initBitmapLines();
var
  i: integer;
begin
  setLength(bitmapLines, bitmapHeight);

  for i:=0 to bitmapHeight-1 do
    begin
    bitmapLines[i] := image.Picture.Bitmap.ScanLine[i];
    end;
end;


{*
 * simul
 *
 * M�thode r�gissant la propagation des ondes sur la grille
 *}
procedure TMainForm.simul();
var
  x: integer;
  y: integer;

  // D�riv�es premieres
  d1: double;
  d2: double;

  // D�riv�e seconde
  ddx: double;
  ddy: double;

  viscosity1: double;
begin
  // Les bords de l'image ne sont pas calcul�s car leur calcul n�cessitent des point de la grille
  // qui sortent du tableau ( waves[x-1, y] par exemple ).
  for x:=1 to bitmapWidth-1 do
  for y:=1 to bitmapHeight-1 do
    begin
    // Formule du calcul:
    // acc�l�ration de la hauteur = double d�riv�e de la hauteur au point concern�
    //
    // d�h     d�h   d�h          1
    // --- = ( --- + --- ) x ------------
    // dt�     dx�   dy�      wavesSpeed
    //
    // La d�riv�e de la hauteur repr�sente la "pente" au point concern�. 

    // Traitement sur X
    d1 := waves[x+1, y].height - waves[x, y].height;   // D�riv�e premi�re � "droite" de x
    d2 := waves[x, y].height   - waves[x-1, y].height; // D�riv�e premi�re � "gauche" de x
    ddx := d1 - d2;                                    // D�riv�e seconde en x

    // Traitmement sur Y
    d1 := waves[x, y+1].height - waves[x, y].height;
    d2 := waves[x, y].height   - waves[x, y-1].height;
    ddy := d1 - d2;
    
    waves[x, y].speed := waves[x, y].speed + ddx/wavesSpeed + ddy/wavesSpeed;
    end;

  // Application de la vitesse et de la viscosit�
  // Ce calcul ne peut pas �tre effectu� dans la premi�re boucle car les modifications seraient
  // utilis�es dans les calculs des cellules suivantes.
  viscosity1 := 1.0-viscosity;  
  for x:=1 to bitmapWidth-1 do
  for y:=1 to bitmapHeight-1 do
    begin
    waves[x, y].height := (waves[x, y].height + waves[x, y].speed)*viscosity1;
    end;
end;

{*
 * simul edges
 *
 * Traitement des bords de la grille. Les valeurs des bords sont copi�es depuis les points voisins
 * de la grille afin d'obtenir la r�flexion correcte des ondes. Sans cette �tape les ondes seraient
 * invers�es lors de la r�flexion, m�me si ce n'est pas tr�s visible, ce n'est pas correcte :)
 *}
procedure TMainForm.simulEdges();
var
  x: integer;
begin
  // Les points (0, 0) et (bitmapWidth, 0) sont trait�s dans la seconde boucle.
  for x:=1 to bitmapWidth-1 do
    begin
    waves[x, 0] := waves[x, 1];
    waves[x, bitmapHeight] := waves[x, bitmapHeight-1];
    end;
  for x:=0 to bitmapHeight do
    begin
    waves[0, x] := waves[1, x];
    waves[bitmapWidth, x] := waves[bitmapWidth-1, x];
    end;
end; 


{*
 * ripple
 *
 * Cr� une perturbation � la surface de l'eau en force de vague de rayon radius et d'amplitude
 * height.
 *}
procedure TMainForm.ripple(centerX, centerY, radius: integer; height: double);
var
  x: integer;
  y: integer;
begin
  for x:=(centerX-radius) to centerX+radius-1 do
    begin

    if (x>=0) and (x<=bitmapWidth) then
    for y:=centerY-radius to centerY+radius-1 do
      begin

      if (y>=0) and (y<=bitmapHeight) then
        begin
        // Forme de la perturbation obtenue � l'aide de la fonction cosinus
        //                      ____
        //                   __/    \__
        //                 _/          \_
        //                /              \
        //              _/                \_
        //           __/                    \__
        // _________/                          \_________
        waves[x, y].height := waves[x, y].height +( (Cos((x-centerX+radius)/(2*radius)*2*PI - PI)+1)*(Cos((y-centerY+radius)/(2*radius)*2*PI - PI)+1)*height );
        end;

      end;

    end;
end; 


{*
 * render
 *}
procedure TMainForm.render();
var
  x: integer;
  y: integer;

  background: PByteArray;
  buffer    : PByteArray;

  // Refraction
  dx: double;
  dy: double;
  light: integer;
  xMap: integer;
  yMap: integer;
begin
  // Pour chaque colone
  for y:=0 to bitmapHeight-1 do
    begin
    // R�cup�ration de la colone du background et de l'image
    //buffer := image.picture.bitmap.scanLine[y];

    for x:=0 to bitmapWidth-1 do
      begin
      // D�riv�e X et Y
      dx := waves[x+1, y].height-waves[x, y].height;
      dy := waves[x, y+1].height-waves[x, y].height;

      // Calcul d�formation
      xMap := x + round(dx*(waves[x,y].height+depth));
      yMap := y + round(dy*(waves[x,y].height+depth));

      // Modification de xMap et yMap pour la faible r�solution afin d'avoir une image de meme
      // taille � l'�cran qu'en haute r�solution
      if halfResolution then
        begin
        xMap := xMap * 2;
        yMap := yMap * 2;
        end;

      // Calcul lumi�re
      //light := max(0, round(dx*lightIntensity + dy*lightIntensity));
      light := round(dx*lightIntensity + dy*lightIntensity);

      if xMap>=0 then
        xMap := xMap mod backgroundBitmap.Width
        else
        xMap := backgroundBitmap.Width-((-xMap) mod backgroundBitmap.Width)-1;

      if yMap>=0 then
        yMap := yMap mod backgroundBitmap.Height
        else
        yMap := backgroundBitmap.Height-((-yMap) mod backgroundBitmap.Height)-1;

      bitmapLines[y][x*3+0] := min(255, max(0, backgroundLines[yMap][xMap*3+0] + light));
      bitmapLines[y][x*3+1] := min(255, max(0, backgroundLines[yMap][xMap*3+1] + light));
      bitmapLines[y][x*3+2] := min(255, max(0, backgroundLines[yMap][xMap*3+2] + light));

      end;

    end;

  image.Refresh();
end;


{*
 * event onCreate
 *}
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Initialisation
  init();
end;


{*
 * event scrollBar1Change
 *}
procedure TMainForm.ScrollBar1Change(Sender: TObject);
begin
  lightIntensity := ScrollBar1.Position;
  render();
end;


{*
 * event scrollBar2Change
 *}
procedure TMainForm.ScrollBar2Change(Sender: TObject);
begin
  depth := ScrollBar2.Position/10.0;
  render();
end;


{*
 * event scrollBar3Change
 *}
procedure TMainForm.ScrollBar3Change(Sender: TObject);
begin
  viscosity := scrollBar3.Position/100;
end;


{*
 * event scrollBar4Change
 *}
procedure TMainForm.ScrollBar4Change(Sender: TObject);
begin
  wavesSpeed := scrollBar4.Position;
end;


{*
 * event imageMouseDown
 *}
procedure TMainForm.ImageMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if halfResolution then
    begin
    x := x div 2;
    y := y div 2;
    end;

  ripple(x, y, 15, -1);
  leftDown := true;
end;


{*
 * event imageMouseUp
 *}
procedure TMainForm.ImageMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  leftDown := false;
end;


{*
 * event imageMouseMove
 *}
procedure TMainForm.ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if halfResolution then
    begin
    x := x div 2;
    y := y div 2;
    end;

  if LeftDown then
    ripple(x, y, 15, -1);
end;


{*
 * event comboBox1Select
 *}
procedure TMainForm.ComboBox1Select(Sender: TObject);
begin
  initBackgroundBitmap(comboBox1.Text);
  initBackgroundLines();
end;

end.
