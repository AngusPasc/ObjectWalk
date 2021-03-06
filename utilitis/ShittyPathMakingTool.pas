program ShittyPathMakingTool;
{==============================================================================]
  Some stupid tool to generate paths..
  It will have to do for now, it's kind of a bitch to use tho.


  Start instructions..:
  > Start it once to boot up smart... log in and whatnots..
  > Target smart with Simba's targeting thingy.

  Usage instructions..:
  Do not move in the following process, and have compass at North..:
  > Left-click on objects (marked as squares) [3+ is good with 2+ of different types is best]
  > Right-Click to select the actual point you wanna walk to `Goal`.
  > Click "Done".. Your first step has just been made.

  Now you can click through the minimap, so walk to the `Goal` point you just set..
  > Click the button that now says `DISABLED` to start blocking input again (so you don't walk around)
  > Repeat the process above..

  When you are done, you can print the path you just made by clocking `PRINT`
  If you make mistakes, simply press clear to reset that step.

  Restart the tool (stop + start the script) to make a new path ^____-
[==============================================================================}
{$hints off}
{$define SMART}
{$I SRL/OSR.simba}
{$DEFINE OW:SMARTDEBUG}
{$I ObjectWalk/Walker.simba}

type
  EButtonType = (btCapture, btClear, btDone, btPrintPath);

var
  client2:TClient;
  isCapturing:Boolean = True;
  isCompleted: Boolean;

  Buttons: array [EButtonType] of TBox = [
    [706,02,762,18],
    [715,20,762,36],
    [722,38,762,54],
    [726,56,762,72]
  ];

var
  Walker: TObjectWalk;
  path:TMMPath;
  DTM:TMMDTM;
  Goal:TPoint;


function ToString(X:TMMDTM): String; override;
var i:Int32;
begin
  Result := '[';
  for i:=0 to High(X) do
  begin
    Result += '['+ToString(X[i].typ)+','+ToString(X[i].x)+','+ToString(X[i].y)+']';
    if i <> High(X) then Result += ',';
  end;
  Result += ']';
end;

function ToString(X:TPoint): String; override;
begin
  Result := '['+ToString(X.x)+','+ToString(X.y)+']';
end;



procedure Init();
begin
  client2.Init(PluginPath);
  client2.getIOManager.SetTarget2(GetNativeWindow());

  srl.Debugging := False;
  Smart.EnableDrawing := True;
  //Smart.JavaPath := 'D:\Java7-32\bin\javaw.exe';
  Smart.Init();

  mouse.SetSpeed(39);
  Walker.Init();
end;


procedure ReDrawInterface();
begin
  if isCapturing then
  begin
    smart.Image.DrawTPA(TPAFromBox(Buttons[btCapture]), $009900);
    smart.Image.DrawBox(Buttons[btCapture], 1);
    smart.Image.DrawText('ENABLED',Point(Buttons[btCapture].x1+3,Buttons[btCapture].y1+3), $FFFFFF);
  end else
  begin
    smart.Image.DrawTPA(TPAFromBox(Buttons[btCapture]), $000099);
    smart.Image.DrawBox(Buttons[btCapture], 1);
    smart.Image.DrawText('DISABLED',Point(Buttons[btCapture].x1+3,Buttons[btCapture].y1+3), $FFFFFF);
  end;

  begin
    smart.Image.DrawTPA(TPAFromBox(Buttons[btClear]), $333333);
    smart.Image.DrawBox(Buttons[btClear], 1);
    smart.Image.DrawText('CLEAR',Point(Buttons[btClear].x1+3,Buttons[btClear].y1+3), $FFFFFF);
  end;

  begin
    smart.Image.DrawTPA(TPAFromBox(Buttons[btDone]), $333333);
    smart.Image.DrawBox(Buttons[btDone], 1);
    smart.Image.DrawText('DONE',Point(Buttons[btDone].x1+3,Buttons[btDone].y1+3), $FFFFFF);
  end;

  begin
    smart.Image.DrawTPA(TPAFromBox(Buttons[btPrintPath]), $333333);
    smart.Image.DrawBox(Buttons[btPrintPath], 1);
    smart.Image.DrawText('PRINT',Point(Buttons[btPrintPath].x1+3,Buttons[btPrintPath].y1+3), $FFFFFF);
  end;
end;

procedure RedrawObjects();
var i:Int32;
begin
  Walker.DebugMinimap(smart.Image);
  for i:=0 to High(DTM) do
    smart.Image.DrawCircle(Point(dtm[i].x,dtm[i].y), 3, False, $FFFFFF);

  if Goal <> [0,0] then
    smart.Image.DrawCircle(Point(Goal.x,Goal.y), 3, True, 255);
end;


procedure ToggleCapture();
begin
  isCapturing := not isCapturing;
end;


procedure ClearDTM();
begin
  SetLength(DTM, 0);
  Goal := [0,0];
end;


procedure FinalizeDTM();
begin
  if (Goal <> [0,0]) then
  begin
    Mouse.Click(goal, mouse_Left);
    SetLength(path, Length(path)+1);
    path[high(path)].Objects := DTM;
    path[high(path)].Dest    := [goal];
    WriteLn('---------------------------------------------------------');
    WriteLn('Path[',high(path),'].Objects := ', path[high(path)].Objects,';');
    WriteLn('Path[',high(path),'].Dest    := ', path[high(path)].Dest,';');
    WriteLn('---------------------------------------------------------');
    SetLength(DTM,0);
    Goal := [0,0];
    minimap.WaitFlag();
  end else
    WriteLn('Path is incomplete, select goal by right-clicking where you want to walk');
end;

procedure OutputPath();
var i:Int32;
begin
  ClearDebug();
  WriteLn('SetLength(path, ', Length(path),');');
  for i:=0 to High(path) do
  begin
    WriteLn('Path[',i,'].Objects := ', path[i].Objects ,';');
    WriteLn('Path[',i,'].Dest    := ', path[i].Dest ,';');
  end;
end;


procedure SelectObject(pos:TPoint; clickType:Int32);
var
  i,h:Int32;
  TPA:TPointArray;
begin
  if clickType = 0 then
  begin
    for i:=0 to High(MMObjRecords) do
    begin
      TPA := Minimap.FindObj(MMObjRecords[i]);
      SortTPAFrom(TPA, pos);
      if (Length(TPA) > 0) and (Distance(TPA[0],pos) <= 2) then
      begin
        h := Length(DTM);
        SetLength(DTM, h+1);
        DTM[h].x := TPA[0].x;
        DTM[h].y := TPA[0].y;
        DTM[h].typ := EMinimapObject(i);
        WriteLn('Selected: ', DTM[h]);
        Exit();
      end;
    end;
  end else
  begin
    WriteLn('Goal set to ', pos);
    Goal := pos;
  end;
end;


procedure HandleClick();
var
  i,click:Int32 = -1;
  pos:TPoint;

  function ValidClick(pos:TPoint): Boolean;
  var v,W,H:Int32;
  begin
    client2.GetIOManager.GetPosition(v,v);
    if v > 30000 then Exit(False);

    client2.GetIOManager.GetDimensions(W,H);
    Result := (pos.x >= 0) and (pos.x < W) and (pos.y >= 0) and (pos.y < H);
  end;

begin
  client2.GetIOManager.GetMousePos(pos.x,pos.y);
  if client2.GetIOManager.IsMouseButtonDown(0) then
    click := 0
  else if (client2.GetIOManager.IsMouseButtonDown(1)) then
    click := 1;

  if (click = -1) then Exit;
  while client2.GetIOManager.IsMouseButtonDown(click) do Wait(5);
  if (not ValidClick(pos)) then Exit;

  if pos.InBox(Buttons[btCapture]) and (click = 0) then
  begin
    ToggleCapture();
    ReDrawInterface();
    Exit();
  end else if pos.InBox(Buttons[btClear]) and (click = 0) then
  begin
    ClearDTM();
    Exit();
  end else if pos.InBox(Buttons[btDone]) and (click = 0) then
  begin
    FinalizeDTM();
    ReDrawInterface();
    Exit();
  end else if pos.InBox(Buttons[btPrintPath]) and (click = 0) then
  begin
    OutputPath();
    Exit();
  end;

  if (not isCapturing) then
    Mouse.Click(pos, ([1,0][click]))
  else
  begin
    SelectObject(pos, click);
  end;
end;



var lastTick:UInt64;
begin
  Init();

  ReDrawInterface();
  Walker.DebugMinimap(smart.Image,,False);
  lastTick := GetTickCount64();

  while True do
  begin
    HandleClick();
    if GetTickCount64() - lastTick > 64 then
    begin
      RedrawObjects();
      lastTick := GetTickCount64();
    end;
  end;
end.
