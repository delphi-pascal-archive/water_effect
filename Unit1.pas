//**************************************************************************************************
// Propagation des ondes
//
// Auteur: neodelphi
//         neodelphi@hotmail.com
//
// Date: 31/10/2005
//
// Description: Ce source met en application les équations de propagations des ondes sur un plan
//              d'eau. La physique est adapté pour le programme et certains calculs sont simplifiés
//              dans le seul but d'obtenir un rendu "réaliste".
//
//              Dans un premier temps le programme calcule la propagation des ondes sur le plan
//              d'eau, puis un rendu avec pseudo-réfraction d'une image en arrière plan permet de
//              visualiser le résultat.
//
// Remarques:   Les fichiers arrière plans sont dans le répertoire backgrounds\ et doivent être au
//              format bmp. Aucune contrainte n'est fixée sur la taille des images, le rendu
//              duplique le motif si nécessaire (voir checker.bmp).
//
//              Le programme gère un mode de rendu basse qualité pour les machines plus lentes.
//**************************************************************************************************
unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Math, XPMan, Menus;

type


  // Donné d'un élément sur la grille du plan d'eau
  // Correspond à la hauteur et vitesse de l'eau en un point
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
    { Déclarations privées }
  public
    // Méthodes d'initialisation
    procedure init();
    procedure initBitmap();
    procedure initBackgroundsNames();
    procedure initBackgroundBitmap(fileName: string);
    procedure initWavesArray();
    procedure initWavesData();
    procedure initBackgroundLines();
    procedure initBitmapLines();

    // Méthodes de simulation
    procedure simul();
    procedure simulEdges();
    procedure ripple(centerX, centerY, radius: integer; height: double);    

    procedure render();
    procedure idle(sender: TObject; var done: boolean);
    procedure fps();
  end;

var
  MainForm: TMainForm;

  // Répertoire de travail de l'application (initialisé dans la méthode init) 
  rep: string;

  // Dimensions du bitmap
  // La dimensions de la grille pour l'eau est (bitmapWidth+1)x(bitmapHeight+1)
  bitmapWidth    : integer;
  bitmapHeight   : integer;
  backgroundLines: array of PByteArray;
  bitmapLines    : array of PByteArray;
  halfResolution : boolean;

  // Bitmap de l'image de fond (chargé dans la méthode initBackgroundBitmap) et liste des fichiers
  // image
  backgroundBitmap: TBitmap;
  backgroundsNames: TStringList;

  // Grille des vagues (initialisé dans initWavesArray)
  waves: array of array of TWave;

  // Parmêtres de rendu et d'animation:
  lightIntensity: double; // Intensité de l'effet de lumière
  depth         : double; // Profondeur de l'eau pour la pseudo-réfraction
  viscosity     : double; // pseudo-viscosité pour l'animation
  wavesSpeed    : double; // paramêtre pour la vitesse des vagues (doit valoir au minimum 2.0)

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
 * Méthode appelée dès que le programme est libre, c'est a dire beaucoup de fois par seconde !
 * Cette méthode permet de réaliser une boucle d'animation tout en laissant la possibilité à
 * l'utilisateur de clicker sur les composants de la fenêtre.
 *}
procedure TMainForm.idle(sender: TObject; var done: boolean);
begin
  // Animation seulement si la case est cochées !
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
 * Affiche toutes les secondes le nombre d'images calculées lors de la dernière seconde.
 *}
procedure TMainForm.fps();
var
  t: integer;
begin
  // Récupération du temps actuel en ms
  t := getTickCount;

  // Si ça fait plus d'une seconde que l'on a calculé le fps, on le recalcul
  if t-lastT>=1000 then
    begin
    caption :='Water Effect ('+ inttostr(fpsCount) + ' FPS)';
    lastT := t;
    // Remise à zero du compteur d'images
    fpsCount := 0;
    end
    else
    begin
    // ... sinon on incrément le compteur d'images
    inc(fpsCount);
    end;
end;


{*
 * init
 *}
procedure TMainForm.init();
begin
  // Extraction du répertoire racine
  rep := ExtractFilePath(application.exeName);

  // Faible résolution pour les machines lentes ?
  // La faible résolution utilise le stretching de l'image et ne calcul q'un quart de l'image
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

  // Initialisation du bitmap d'arrière plan
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
  // Modifier cette méthode pour avoir une configuration de vagues initiale
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
 * Etabli la liste des arrières plans au format bmp
 *}
procedure TMainForm.initBackgroundsNames();
var
  searchRec: TSearchRec;
begin
  backgroundsNames := TStringList.Create();

  // Liste les images du répertoire backgrounds\
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
  // Si le bitmap n'existe pas déjà (initialisation) on le cré
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
 * Méthode régissant la propagation des ondes sur la grille
 *}
procedure TMainForm.simul();
var
  x: integer;
  y: integer;

  // Dérivées premieres
  d1: double;
  d2: double;

  // Dérivée seconde
  ddx: double;
  ddy: double;

  viscosity1: double;
begin
  // Les bords de l'image ne sont pas calculés car leur calcul nécessitent des point de la grille
  // qui sortent du tableau ( waves[x-1, y] par exemple ).
  for x:=1 to bitmapWidth-1 do
  for y:=1 to bitmapHeight-1 do
    begin
    // Formule du calcul:
    // accèlération de la hauteur = double dérivée de la hauteur au point concerné
    //
    // d²h     d²h   d²h          1
    // --- = ( --- + --- ) x ------------
    // dt²     dx²   dy²      wavesSpeed
    //
    // La dérivée de la hauteur représente la "pente" au point concerné. 

    // Traitement sur X
    d1 := waves[x+1, y].height - waves[x, y].height;   // Dérivée première à "droite" de x
    d2 := waves[x, y].height   - waves[x-1, y].height; // Dérivée première à "gauche" de x
    ddx := d1 - d2;                                    // Dérivée seconde en x

    // Traitmement sur Y
    d1 := waves[x, y+1].height - waves[x, y].height;
    d2 := waves[x, y].height   - waves[x, y-1].height;
    ddy := d1 - d2;
    
    waves[x, y].speed := waves[x, y].speed + ddx/wavesSpeed + ddy/wavesSpeed;
    end;

  // Application de la vitesse et de la viscosité
  // Ce calcul ne peut pas être effectué dans la première boucle car les modifications seraient
  // utilisées dans les calculs des cellules suivantes.
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
 * Traitement des bords de la grille. Les valeurs des bords sont copiées depuis les points voisins
 * de la grille afin d'obtenir la réflexion correcte des ondes. Sans cette étape les ondes seraient
 * inversées lors de la réflexion, même si ce n'est pas très visible, ce n'est pas correcte :)
 *}
procedure TMainForm.simulEdges();
var
  x: integer;
begin
  // Les points (0, 0) et (bitmapWidth, 0) sont traités dans la seconde boucle.
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
 * Cré une perturbation à la surface de l'eau en force de vague de rayon radius et d'amplitude
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
        // Forme de la perturbation obtenue à l'aide de la fonction cosinus
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
    // Récupération de la colone du background et de l'image
    //buffer := image.picture.bitmap.scanLine[y];

    for x:=0 to bitmapWidth-1 do
      begin
      // Dérivée X et Y
      dx := waves[x+1, y].height-waves[x, y].height;
      dy := waves[x, y+1].height-waves[x, y].height;

      // Calcul déformation
      xMap := x + round(dx*(waves[x,y].height+depth));
      yMap := y + round(dy*(waves[x,y].height+depth));

      // Modification de xMap et yMap pour la faible résolution afin d'avoir une image de meme
      // taille à l'écran qu'en haute résolution
      if halfResolution then
        begin
        xMap := xMap * 2;
        yMap := yMap * 2;
        end;

      // Calcul lumière
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
