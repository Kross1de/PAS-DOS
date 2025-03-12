Program OSystem;

uses CRT, DOS;

const

	VK_BACKSPACE = 8;
  VK_RETURN 	 = 13;

  UA_USER = 0;
  UA_ROOT = 1;

type TUser = record
			 ID: Byte;
			 Name: String[32];
       Password: String[79];
       Access: Byte;
     end;

     TUserDB = record
       ID: Byte;
     	 Name: String[32];
       isUser: Boolean;
     end;

var Dir, D, P, CMD, arg, S, Script: String;
    isCMD, doExit, userLogged, ECHO, runScript: Boolean;
    loggedUser: TUser;
    Users: array[0..255] of TUserDB;
    UsersCount, FG, BG: Byte;
    TF: Text;


procedure pressAnyKey;
begin
	While(KeyPressed) do;
  ReadKey;
end;

procedure fatalError(S: String);
begin
	TextColor(RED);
	ClrScr;
	GotoXY(35, 12);
  Write('FATAL ERROR');
	GotoXY(40 - (Length(S) div 2), 13);
  Write(S);
  pressAnyKey;
  doExit := True;
end;

function isInt(S: String): Boolean;
var I: Byte;
begin

	isInt := True;

	for I := 1 to Length(S) do
  begin
  	if(not(S[I] in ['0'..'9'])) then
    begin
    	isInt := False;
    	break;
    end;
  end;

end;

function StrToInt(S: String): Integer;
var I, C: Integer;
begin

	if(isInt(S)) then Val(S, I, C)
  else fatalError(S+' is not numeric value.');
  StrToInt := I;

end;

function IntToStr(I: Integer): String;
var S: String;
begin
	Str(I, S);
  IntToStr := S;
end;

procedure lowercase(var S: String);
var I: byte;
begin

	for I := 1 to Length(S) do
  	if(S[I] in ['A'..'Z']) then
    	S[I] := Chr(Ord(S[I]) + 32);

end;

procedure explodeForUser(S: String; var User: TUserDB);
begin
	User.ID := StrToInt(copy(S, 1, Pos(':', S) - 1));
  User.Name := copy(S, Pos(':', S)+1, Length(S) - Pos(':', S));
  User.isUser := True;
end;

procedure LoadUserTable;
var TF: Text;
		S: String;
    I: Byte;
begin

	UsersCount := 0;

	for I := 0 to 255 do
  begin
  	Users[I].ID := 0;
  	Users[I].Name := '';
    Users[I].isUser := False;
  end;

  Assign(TF, DIR+'\SYSTEM\users.tdb');
  ReSet(TF);

  While(not EOF(TF)) do
  begin
    ReadLn(TF, S);
    explodeForUser(S, Users[UsersCount]);
    Inc(UsersCount);
  end;

  Close(TF);

end;

procedure postExit;
begin
	chDir(Dir);
  Exit;
end;

function fileExists(name: String): Boolean;
var SR: SearchRec;
		Res: Integer;
begin

	FindFirst(name, AnyFile - Directory, SR);
  fileExists := (DosError = 0);

end;

function dirExists(name: String): Boolean;
var SR: SearchRec;
begin

	dirExists := False;
	FindFirst(name, Directory, SR);
	if(DosError = 0) then
  begin
  	if(not fileExists(name)) then
    begin
    	dirExists := True;
    end;
  end;

end;

procedure dirContent(Mask: String);
var SR: SearchRec;
begin
  if(Length(Mask) = 0) then Mask := '*.*';

	FindFirst(Mask, Directory, SR);
  While(DosError = 0) do
  begin
  	Write(SR.Name);
    Write(SR.Size:40-Length(SR.Name), 'B');
    if(dirExists(SR.Name)) then Write(' [DIR]');
    Writeln;
    FindNext(SR);
  end;
end;

function dirExistsRLName(name: String; var RLName: String): Boolean;
var SR: SearchRec;
begin

	dirExistsRLName := False;
	FindFirst(name, Directory, SR);
  if(DosError = 0) then
  begin
  	if(not fileExists(name)) then
    begin
    	dirExistsRLName := True;
    	RLName := SR.Name;
    end;
  end;

end;

procedure explode(S, By: String; var A, B: String);
begin

	B := '';

  if(Pos(By, S) <> 0) then
  begin
    A := copy(S, 1, Pos(By, S) - 1);
    B := copy(S, Pos(By, S) + 1, Length(S) - Pos(By, S) + 1);
  end else A := S;
end;

procedure parseCMD(var CMD: String);
begin

	explode(CMD, ' ', CMD, arg);

end;

procedure readPassword(var S: String);
var Key: Char;
begin

	repeat

  	Key := ReadKey;

    if( (Ord(Key) <> VK_BACKSPACE) and (Ord(Key) <> VK_RETURN) ) then
    begin
    	if(Length(S) < 79) and (Key in [' '..'}']) then
      begin
    		S[Length(S)+1] := Key;
      	S[0] := Chr(Length(S) + 1);
      	Write('*');
    	end;
    end
    else
		begin
			Write(Key);
      if(Ord(Key) = VK_BACKSPACE) and (Length(S) > 0) then
      begin
      	Write(' ');
        Write(Key);
        S[Length(S)] := Chr(0);
        S[0] := Chr(Length(S) - 1);
      end;
    end;

  until(Ord(Key) = VK_RETURN);

end;

procedure updir(var Dir: String);
var I: Byte;
begin

	for I := Length(Dir)-1 downto 1 do
  begin
  	if(Dir[I] = '\') then
    begin
    	Dir := copy(Dir, 1, I);
      break;
    end;
  end;

end;

procedure chColor(arg: String);
var A, B: String;
		I: Byte;
begin

	if(Length(Arg) <> 0) then
  begin

		explode(arg, ',', A, B);

  	if(A = 'D') and (B = 'D') then
		begin
  		textColor(7);
    	textBackground(BLACK);
	  end
		else
	  begin

  		if(Length(A) > 0) then
    	  if(isInt(A)) then
      		if(StrToInt(A) in [0..15]) then
					begin
						textColor(StrToInt(A));
            FG := StrToInt(A);
          end;

	    if(Length(B) > 0) then
  	  	if(isInt(B)) then
    	  	if(StrToInt(B) in [0..7]) then
					begin
						textBackground(StrToInt(B));
            BG := StrToInt(B);
          end;
	  end;
  end
  else
  begin
   	textColor(7);
    textBackground(0);

  	Writeln('usage: COLOR FG(0-15),BG(0-7)');
    Writeln;
  	for I := 0 to 15 do
    begin
    	textColor(7);

      Write(I, ': ');

      textColor(I);

      Writeln('^^');
    end;

    textColor(FG);
    textBackground(BG);
  end;

end;

function userExists(name: String): Boolean;
var I: Integer;
begin

	lowercase(name);
  userExists := False;

	for I := 0 to UsersCount - 1 do
  begin
  	if(Users[I].isUser) then
    begin
    	if(Users[I].Name = name) then
      begin
        userExists := True;
        break;
      end;
    end;
  end;


end;

procedure saveUser(var User: TUser);
var TF: Text;
		UF: File of TUser;
    I: Byte;
begin

	Assign(TF, DIR+'\SYSTEM\users.tdb');
  ReWrite(TF);

  for I := 0 to UsersCount - 1 do
    Writeln(TF, Users[I].ID, ':', Users[I].Name);

  Close(TF);

  Assign(UF, DIR+'\SYSTEM\USER\'+IntToStr(User.ID)+'.usr');
  ReWrite(UF);
  Write(UF, User);
  Close(UF);

end;

procedure addUser(name: String);
var pass: String;
		User: TUser;
begin

	while( (Length(name) < 4) or (Length(name) > 32) or (userExists(name)) )do
  begin
    Write('Username (32 chars): ');
    Readln(name);
    if(userExists(name)) then Writeln('User with that username already exists.');
  end;

  repeat
  	pass := '';
  	Writeln('Password (7-79 chars):');
  	readPassword(pass);
  until(Length(pass) >= 7);


  lowercase(name);

  User.Name := name;
  User.Password := pass;
  User.ID := UsersCount;
  if(UsersCount = 0) then User.Access := UA_ROOT
  else User.Access := UA_USER;


  Users[UsersCount].Name := name;
  Users[UsersCount].ID := UsersCount;
  Users[UsersCount].isUser := True;


  Inc(UsersCount);

  saveUser(User);

  Writeln('User has been created.');

end;

function getUserID(Name: String): Byte;
var I: Byte;
begin

	lowercase(name);

	if(userExists(Name))then
  begin
		for I := 0 to UsersCount - 1 do
    begin
    	if(Users[I].isUser) then
      begin
	    	if(Users[I].Name = Name) then
  	    begin
    	  	getUserID := Users[I].ID;
      	  break;
	      end;
      end;
    end;
  end else fatalError('Wrong user name to get its ID.');

end;

procedure loadUser(ID: Byte; var User: TUser);
var UF: File of TUser;
begin

	Assign(UF, DIR+'\SYSTEM\USER\'+IntToStr(ID)+'.usr');
  Reset(UF);
  Read(UF, User);
  Close(UF);

end;

procedure login(name: String);
var pass: String;
		I: Byte;
    User: TUser;
begin
  if(Length(Name) = 0) then
  begin
	  Write('Username: ');
  	Readln(name);
  end;

  if(userExists(name)) then
  begin
    loadUser(getUserID(name), User);

    for I := 1 to 3 do
    begin
      pass := '';
			Writeln('Password:');
      readPassword(pass);
      if(User.Password = pass) then
      begin
        Writeln('Hello ', User.Name, '! You are now logged');
        userLogged := True;
        loggedUser := User;
      	break;
      end else Writeln('Wrong password, try ', I,' of 3.');
    end;
  end else Writeln('User with that username doesn''t exists.');

end;

procedure chPassword(Name: String);
var pass: String;
		passOK: Boolean;
    User: TUser;
    I: Byte;
begin

	if( not loggedUser.Access = UA_ROOT) or (Length(Name) = 0) then
  begin

    for I := 1 to 3 do
    begin
      pass := '';
			Writeln('Current password:');
      readPassword(pass);

      if(loggedUser.Password = pass) then
      begin
        pass := '';

        while(Length(pass) < 7) do
			  begin
			  	Writeln('New password (7-79 chars):');
			  	readPassword(pass);
			  end;

        loggedUser.Password := pass;
        saveUser(loggedUser);
        Writeln('Your password has been changed.');

        break;
      end else Writeln('Wrong password, try ', I,' of 3.');
    end;

  end else
  begin
  	if(userExists(name)) then
    begin
    	loadUser(getUserID(name), User);

      pass := '';

      while(Length(pass) < 7) do
			begin
				Writeln('New password (7-79 chars):');
				readPassword(pass);
			end;

      User.Password := pass;
      saveUser(User);
      Writeln('Password of user "', User.Name, '" has been changed.');


    end else Writeln('User with that user doesn''t exists.');
  end;

end;

procedure allUsers;
var I: Byte;
begin
	Writeln('All users in system: ');
  Writeln;
	for I := 0 to UsersCount - 1 do
  	Writeln(I, ': ', Users[I].Name);

  Writeln;
end;

procedure changeUserAccess(arg: String);
var NewAccess: Byte;
		User: TUser;
    Name, A: String;
begin

  explode(arg, ',', Name, A);

  if(Length(Name) <> 0) and (Length(A) <> 0) then
  begin
		if(isInt(A)) then
    begin

			if(userExists(name)) then
  		begin
  			loadUser(getUserID(Name), User);
		    if(User.ID <> loggedUser.ID) then
		    begin

	        NewAccess := StrToInt(A);

        	if(NewAccess in [0..1]) then
          begin
			      User.Access := NewAccess;
    			  saveUser(User);

            Writeln('Access of user "', User.Name, '" has been changed.');

					end else Writeln('Wrong new access value.');
		    end else Writeln('You cannot change access yourself.');
		  end else Writeln('User with that username dosen''t exists.');
    end else Writeln('New access must be numeric value.');
  end else Writeln('usage: chaccess USERNAME,ACCESS(0-1)');
end;

function rmFile(name: String): Boolean;
var TF: Text;
begin
  {$I-}
  Assign(TF, name);
  Erase(TF);
  {$I+}

  rmFile := (IOResult = 0);
end;

procedure removeFile(name: String);
var TF: Text;
begin

	if(fileExists(name)) then
  begin
    if(rmFile(name)) then Writeln('File has been removed.')
    else Writeln('File with name "', Name, '" cannot be removed.');
  end else Writeln('File with that name doesn''t exists');

end;

function mvFile(A, B: String): Boolean;
var F1, F2: Text;
		S: String;
begin

	mvFile := False;

	if(fileExists(A)) then
  begin
  	if(not fileExists(B)) then
    begin

    	{$I-}
      Assign(F1, A);
      ReSet(F1);
      {$I+}

      if(IOResult = 0) then
      begin

      	{$I-}
        Assign(F2, B);
        ReWrite(F2);
        {$I+}

        if(IOResult = 0) then
        begin

          While(not EOF(F1)) do
          begin
            Readln(F1, S);
            Writeln(F2, S);
          end;

        	Close(F1);
          Close(F2);
          rmFile(A);

          mvFile := True;

        end
				else
				begin
					fatalError('moveFile: File B cannot be open for write.');
          Close(F1);
        end;
      end else fatalError('moveFile: File A cannot be open for read.');
    end else fatalError('moveFile: File B already exists');
  end else fatalError('moveFile: File A doesn''t exists.');

end;

procedure removeFileLine(arg: String);
var A, Name, S: String;
		I, LineNO: Integer;
    TF, TTF: Text;
begin

	explode(arg, ',', A, Name);
  if(Length(A) <> 0) and (Length(Name) <> 0) then
  begin
		if(fileExists(Name)) then
  	begin
  		if(isInt(A)) then
	    begin
  	  	LineNO := StrToInt(A);
    	  {$I-}
      	Assign(TF, Name);
	      Reset(TF);
  	    {$I+}
    	  if(IOResult = 0) then
      	begin

		      {$I-}
  		    Assign(TTF, DIR+'\SYSTEM\TEMP\'+Name);
    	    ReWrite(TTF);
     		  {$I+}

		      if(IOResult = 0) then
	  	    begin
    		    I := 0;
      	    While(not EOF(TF)) do
        	 	begin
       	  		Inc(I);
           		Readln(TF, S);
		          if(I <> LineNO) then
  		        begin
    		      	Writeln(TTF, S);
      		    end;
        	  end;

		        Close(TF);
  		      Close(TTF);

						if(rmFile(Name)) then
        	  begin
          	  if(mvFile(DIR+'\SYSTEM\TEMP\'+Name, Name)) then Writeln('Line has been removed')
            	else fatalError('Cannot move temporary file.');
	          end else fatalError('Cannot remove original file.');
		      end
					else
      	  begin
						Writeln('Cannot create temporary file.');
  	        Close(TF);
    	    end;
      	end else Writeln('Cannot open file for read.');
	    end else Writeln('Line number must be a numeric value.');
  	end else Writeln('File with that name does''t exists.');
	end else Writeln('Usage: rmline LINENO,FILENAME');

end;

procedure changeFileLine(arg: String);
var A, Name, S: String;
		I, LineNO: Integer;
    TF, TTF: Text;
begin

	explode(arg, ',', A, Name);
  if(Length(A) <> 0) and (Length(Name) <> 0) then
  begin
		if(fileExists(Name)) then
  	begin
  		if(isInt(A)) then
	    begin
  	  	LineNO := StrToInt(A);
    	  {$I-}
      	Assign(TF, Name);
	      Reset(TF);
  	    {$I+}
    	  if(IOResult = 0) then
      	begin

		      {$I-}
  		    Assign(TTF, DIR+'\SYSTEM\TEMP\'+Name);
    	    ReWrite(TTF);
     		  {$I+}

		      if(IOResult = 0) then
	  	    begin
    		    I := 0;
      	    While(not EOF(TF)) do
        	 	begin
       	  		Inc(I);
           		Readln(TF, S);
		          if(I <> LineNO) then
  		        begin
    		      	Writeln(TTF, S);
      		    end
              else
              begin
              	Writeln('Line that you want to change:');
              	Writeln(S);
              	Writeln('Type new line:');
                Readln(S);
                Writeln(TTF, S);
              end;
        	  end;

		        Close(TF);
  		      Close(TTF);

						if(rmFile(Name)) then
        	  begin
          	  if(mvFile(DIR+'\SYSTEM\TEMP\'+Name, Name)) then Writeln('Line has been changed')
            	else fatalError('Cannot move temporary file.');
	          end else fatalError('Cannot remove original file.');
		      end
					else
      	  begin
						Writeln('Cannot create temporary file.');
  	        Close(TF);
    	    end;
      	end else Writeln('Cannot open file for read.');
	    end else Writeln('Line number must be a numeric value.');
  	end else Writeln('File with that name does''t exists.');
	end else Writeln('Usage: chline LINENO,FILENAME');

end;


procedure appendFileLine(name: String);
var TF: Text;
		S: String;
begin

	if(fileExists(name)) then
  begin

    {$I-}
    Assign(TF, Name);
    Append(TF);
    {$I+}

    if(IOResult = 0) then
    begin

    	Writeln('Type line that you want to append:');
    	Readln(S);

      Writeln(TF, S);

      Close(TF);

      Writeln('Line has been added.');

  	end else Writeln('Cannot open file with name "', name, '" for write.');
  end else Writeln('File with that name doesn''t exists');

end;

procedure createFile(name: String);
var TF: Text;
begin

	if(not fileExists(name)) then
  begin
    if(Length(name) <> 0) then
    begin
	  	{$I-}
  	  Assign(TF, name);
    	ReWrite(TF);
	    {$I+}
  	  if(IOResult = 0) then Writeln('File has been created.')
    	else Writeln('File with name"', name,'" cannot be created.');
    end else Writeln('Cannot create file with empty name.');
  end else Writeln('File with that name already exists.');

end;

procedure copyFile(source, destination: String);
var F1, F2: Text;
    S: String;
begin
     if(fileExists(source)) then
     begin
          if(not fileExists(destination)) then
          begin
               {$I-}
               Assign(F1, source);
               Reset(F1);
               Assign(F2, destination);
               ReWrite(F2);
               {$I+}
               if(IOResult = 0) then
               begin
                    While(not EOF(F1)) do
                    begin
                         Readln(F1, S);
                         Writeln(F2, S);
                    end;
                    Close(F1);
                    Close(F2);
                    Writeln('File copied successfully.');
               end
               else Writeln('Error: Cannot copy file.');
          end
          else Writeln('Error: Destination file already exists.');
     end
     else Writeln('Error: Source file does not exist.');
end;

procedure renameFile(oldName, newName: String);
var F: File;
begin
     if(fileExists(oldName)) then
     begin
          if(not fileExists(newName)) then
          begin
               {$I-}
               Assign(F, oldName);
               Rename(F, newName);
               {$I+}
               if(IOResult = 0) then Writeln('File renamed successfully.')
               else Writeln('Error: Cannot rename file.');
          end
          else Writeln('Error: File with new name already exists.');
     end
     else Writeln('Error: Source file does not exist.');
end;

procedure moveFile(source, destination: String);
var F: File;
begin
     if(fileExists(source)) then
     begin
          if(not fileExists(destination)) then
          begin
               {$I-}
               Assign(F, source);
               Rename(F, destination);
               {$I+}
               if(IOResult = 0) then Writeln('File moved successfully.')
               else Writeln('Error: Cannot move file.');
          end
          else Writeln('Error: Destination file already exists.');
     end
     else Writeln('Error: Source file does not exist.');
end;

procedure readFile(name: String);
var TF: Text;
		C, I: Integer;
    S: String;
begin

	if(fileExists(name)) then
  begin
  	{$I-}
  	Assign(TF, name);
    Reset(TF);
    {$I+}
    If(IOResult = 0) then
    begin
      C := 0;
      I := 0;

      while(not EOF(TF)) do
      begin
        Inc(C);
        Inc(I);
        Readln(TF, S);
        Writeln(I, '| ', S);
        if(C = 24) then
        begin
        	C := 0;
          Write('[Press any key for more]');
          GotoXY(1, 25);
          pressAnyKey;
          Write('                        ');
          GotoXY(1, 25);
        end;
      end;

    	Close(TF);
    end;

  end else Writeln('File with that name doesn''t exists.');

end;

procedure aboutUser(name: String);
var User: TUser;
begin

	User := loggedUser;

	if(loggedUser.Access = UA_ROOT) then
  begin
		if(length(name) <> 0) then
    begin
    	if(userExists(name)) then
      begin
      	loadUser(getUserID(name), User);
      end
			else
			begin
				Writeln('User with that name doesn''t exists.');
      	Exit;
      end;
    end;
  end;

	Writeln(User.ID, ': ', User.Name);
  Write('User access: ');
  case User.Access of
   UA_USER: Writeln('User');
   UA_ROOT: Writeln('Super user');
  end;

end;

procedure removeDirectory(Name: String);
begin
	if(dirExists(Name)) then
  begin
  	{$I-}
    rmDir(Name);
    {$I+}
    if(IOResult = 0) then Writeln('Directory has been removed')
    else Writeln('Directory with name "', Name, '" cannot be removed.');
  end else Writeln('Directory with that name doesn''t exists.');
end;

procedure createDirectory(Name: String);
begin
	if(Length(Name) <> 0) then
  begin
  	if(not dirExists(Name)) then
    begin
   		{$I-}
   		mkDir(Name);
    	{$I+}
    	if(IOResult = 0) then Writeln('Directory has been created.')
    	else Writeln('Directory with name "', Name, '" cannot be created.');
  	end else Writeln('Directory with that name already exists');
  end else Writeln('You cannot create new directory with empty name.');
end;

function isDotOnly(S: String): boolean;
var I: Byte;
begin

	isDotOnly := True;

	for I := 1 to Length(S) do
  begin
  	if(S[I] <> '.') then
    begin
    	isDotOnly := False;
      break;
    end;
  end;

end;

procedure changeDirectory(Name: String);
var RLName: String;
begin
	if(Length(Name) > 0) then
 	begin
 		if(isDotOnly(Name)) then
    begin
    	if(Name = '..') then
 	    begin
   	    updir(D);
     		chDir(Dir+'\'+D);
      end;
    end
 	  else
   	begin
 			if(dirExistsRLName(Name, RLName)) then
   		begin
   			chDir(RLName);
 	  		D := D + RLName + '\';
 			end else Writeln('Directory doesn''t exists.');
    end;
  end else Writeln(D);
end;

procedure textEditor(name: String);
var TF: Text;
    S: String;
    Line: Integer;
begin
     if(userLogged) then
     begin
          if(loggedUser.Access = UA_ROOT) then
          begin
               if(fileExists(name)) then
               begin
                    Writeln('Editing file: ', name);
                    Writeln('Type your text. To save and exit, type "!save".');
                    Writeln('Existing content:');
                    Writeln('-----------------');

                    {$I-}
                    Assign(TF, name);
                    Reset(TF);
                    {$I+}
                    if IOResult = 0 then
                    begin
                         while not EOF(TF) do
                         begin
                              Readln(TF, S);
                              Writeln(S);
                         end;
                         Close(TF);
                    end
                    else
                    begin
                         Writeln('Cannot open file for reading.');
                         Exit;
                    end;

                    Writeln('------------------');
                    Writeln('Start editing:');

                    {$I-}
                    Assign(TF, name);
                    Append(TF);
                    {$I+}
                    if(IOResult = 0) then
                    begin
                         Line := 1;
                         repeat
                               Write(Line, '> ');
                               Readln(S);
                               if(S <> '!save') then
                               begin
                                    Writeln(TF, S);
                                    Inc(Line);
                               end;
                         until(S = '!save');
                         Close(TF);
                         Writeln('File saved.');
                    end
                    else Writeln('Cannot open file for editing.');
               end
               else
               begin
                    Writeln('File does not exist. Creating new file: ', name);
                    {$I-}
                    Assign(TF, name);
                    ReWrite(TF);
                    {$I+}
                    if(IOResult = 0) then
                    begin
                         Line := 1;
                         repeat
                               Write(Line, '> ');
                               Readln(S);
                               if(S <> '!save') then
                               begin
                                    Writeln(TF, S);
                                    Inc(Line);
                               end;
                         until(S = '!save');
                         Close(TF);
                         Writeln('File saved.');
                    end
                    else Writeln('Cannot create file.');
               end;
          end
          else Writeln('Access denied.');
     end
     else Writeln('Access denied.');
end;

function processCMD(CMD: String): Boolean;
var isCMD: Boolean;
begin
	isCMD := False;

	parseCMD(CMD);

  lowercase(CMD);

  if(CMD = 'help') then
  begin
       isCMD := True;
       WriteLn('Available commands:');
       WriteLn(' echo [on|off|message] - Toggle echo or display a message');
       WriteLn(' clear - Clear the screen');
       WriteLn(' color - [FG,BG] - Change text and background color');
       WriteLn(' user [username] - Display information about user');
       WriteLn(' rmdir [dirname] - Remove a directory (requires root access)');
       WriteLn(' mkdir [dirname] - Create a directory (requires root access)');
       WriteLn(' adduser [username] - Add a new user');
       WriteLn(' users - List all users (requires root access)');
       WriteLn(' create [filename] - Create a new file (requires root access)');
       WriteLn(' read [filename] - Read contents of file');
       WriteLn(' rmfile [filename] - Remove a file (requires root access)');
       WriteLn(' append [filename] - Append a line to a file (requires root access)');
       WriteLn(' rmline [lineno,filename] - Remove a line from file (requires root access)');
       WriteLn(' chline [lineno,filename] - Change a line in a file (requires root access)');
       WriteLn(' chaccess [username,access] - Change user access level (requires root access)');
       WriteLn(' logout - Log out from the current user');
       WriteLn(' login [username] - Log in as a user');
       WriteLn(' chpwd [username] - Change password');
       WriteLn(' dir [mask] - List directory contents');
       WriteLn(' cd [dirname] - Change current directory');
       WriteLn(' run [filename] - Run file (requires root access');
       WriteLn(' exit - Exit the system');
       WriteLn(' help - Display this help message');
       WriteLn(' edit [filename] - Edit a text file (requires root access)');
	   WriteLn(' copy [source,destination] - Copy a file (requires root access)');
	   WriteLn(' rename [oldname,newname] - Rename a file (requires root access)');
       WriteLn(' move [source,destination] - Move a file (requires root access)');
  end else

  if(CMD = 'edit') then
  begin
       isCMD := True;
       if(userLogged) then
       begin
            if(loggedUser.Access = UA_ROOT) then textEditor(arg)
            else Writeln('Access denied.');
       end
       else Writeln('Access denied.');
  end else

  if(CMD = 'echo') then
  begin
  	isCMD := True;
    if(arg = 'off') then ECHO := False
		else if(arg = 'on') then ECHO := True
    else Writeln(arg);
  end else
  if(CMD = 'clear') then
  begin
  	isCMD := True;
    ClrScr;
  end else
  if(CMD = 'color') then
  begin
  	isCMD := True;
    chColor(arg);
  end else
  if(CMD = 'user') then
  begin
  	isCMD := True;
  	if(userLogged) then
		begin
			aboutUser(arg);
    end else Writeln('There is no logged user. Login first.');
  end else
  if(CMD = 'rmdir') then
  begin
    isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then removeDirectory(arg)
      else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'mkdir') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then createDirectory(arg)
      else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'adduser') then
  begin
  	isCMD := True;
    addUser(arg);
  end else
  if(CMD = 'users') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then allUsers
      else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'copy') then
  begin
       isCMD := True;
       if(userLogged) then
       begin
            if(loggedUser.Access = UA_ROOT) then
            begin
                 explode(arg, ',', S, D);
                 if(Length(S) > 0) and (Length(D) > 0) then copyFile(S, D)
                 else Writeln('Usage: copy SOURCE,DESTINATION');
            end
            else Writeln('Access denied.');
       end
       else Writeln('Access denied.');
  end else
  if(CMD = 'rename') then
	begin
		isCMD := True;
		if(userLogged) then
		begin
			if(loggedUser.Access = UA_ROOT) then
			begin
				explode(arg, ',', S, D);
				if(Length(S) > 0) and (Length(D) > 0) then renameFile(S, D)
				else Writeln('Usage: rename OLDNAME,NEWNAME');
			end
			else Writeln('Access denied.');
		end
		else Writeln('Access denied.');
	end else
  if(CMD = 'move') then
	begin
		isCMD := True;
		if(userLogged) then
		begin
			if(loggedUser.Access = UA_ROOT) then
			begin
				explode(arg, ',', S, D);
				if(Length(S) > 0) and (Length(D) > 0) then moveFile(S, D)
				else Writeln('Usage: move SOURCE,DESTINATION');
			end
			else Writeln('Access denied.');
		end
		else Writeln('Access denied.');
	end;
  if(CMD = 'create') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then createFile(arg)
      else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'read') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	readFile(arg);
    end else Writeln('Access denied.');
  end else
  if(CMD = 'rmfile') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then removeFile(arg)
      else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'append') then
  begin
    isCMD := True;
    if(userLogged) then
    begin
			if(loggedUser.Access = UA_ROOT) then appendFileLine(arg)
      else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'rmline') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then removeFileLine(arg)
      else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'chline') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then changeFileLine(arg)
      else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'chaccess') then
  begin
    isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then changeUserAccess(arg)
		  else Writeln('Access denied');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'logout') then
  begin
  	isCMD := True;
  	userLogged := False;
    Writeln('You has been logged out.');
  end else
  if(CMD = 'login') then
  begin
  	isCMD := True;
    if(not userLogged) then
    begin
    	login(arg);
    end else Writeln('You are already logged in.');
  end else
  if(CMD = 'chpwd') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
      chPassword(arg);
    end else Writeln('You are not logged in.')
  end else
  if(CMD = 'dir') or (CMD = 'ls') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	Writeln('Content of current directory.');
    	Writeln(D, ': ');
    	Writeln;
  		dirContent(arg);
    end else Writeln('Access denied.');
  end else
  if(CMD = 'cd') then
  begin
  	isCMD := True;
    if(userLogged) then changeDirectory(arg)
    else Writeln('Access denied');
  end else
  if(CMD = 'run') then
  begin
  	isCMD := True;
    if(userLogged) then
    begin
    	if(loggedUser.Access = UA_ROOT) then
      begin
      	if(fileExists(arg)) then
        begin
        	runScript := True;
          Script := arg;
        end else Writeln('File with that name doesn''t exists');
      end else Writeln('Access denied.');
    end else Writeln('Access denied.');
  end else
  if(CMD = 'exit') then
	begin
		isCMD := True;
    doExit := True;
  end;


  if(not isCMD) and (Length(CMD) > 0) then
		Writeln('Error: ', CMD, ' COMMAND NOT FOUND!');

  if(ECHO) then Writeln;

  processCMD := isCMD;
  arg := '';

end;

procedure POST;
var TF: Text;
begin

  GetDir(0, Dir);

  Write('Checking SYSTEM directory...       ');
	if(not dirExists('SYSTEM')) then
	begin
		mkDir('SYSTEM');
    Writeln('created');
  end else Writeln('OK');

  Write('Checking user database file...     ');
  if(not fileExists(DIR+'\SYSTEM\users.tdb')) then
  begin
  	Assign(TF, DIR+'\SYSTEM\users.tdb');
    ReWrite(TF);
    Close(TF);
    Writeln('created');
	end else Writeln('OK');

  chDir('SYSTEM');

  Write('Checking temporiary directory...   ');
  if(not dirExists('TEMP')) then
  begin
		mkDir('TEMP');
  	Writeln('created');
  end else Writeln('OK');

  Write('Checking users directory...        ');
  if(not dirExists('USER')) then
  begin
  	mkDir('USER');
    Writeln('created');
  end else Writeln('OK');

  Write('Loading users database file...     ');
  Writeln('OK');
  LoadUserTable;

  Writeln;

end;

begin
	doExit := False;
  ECHO := True;
  runScript := False;
  FG := 7;
  BG := 0;

	chColor('');
  ClrScr;

  POST;

  D:= 'SYSTEM\';

  Writeln('PAS-DOS [V1.1]');
  Writeln('Copyright (c) Syncas');
  Writeln;

  While(not doExit) do
  begin
  	if(ECHO) then
    begin
	  	if(userLogged) then
  	  begin
    	  case loggedUser.Access of
	      UA_USER: Write('$');
  	    UA_ROOT: Write('#');
    	  end;
	      Write(loggedUser.Name, '@');
  	  end;
   		Write(D, '>');
    end;

    Readln(CMD);
    processCMD(CMD);

    if(runScript) then
    begin

    	{$I-}
      Assign(TF, Script);
      Reset(TF);
      {$I+}

      if(IOResult = 0) then
      begin

       	While(not EOF(TF)) do
        begin
         	Readln(TF, S);
          processCMD(S);
        end;

        Close(TF);

      end else Writeln('Cannot open file with name "', arg, '" for read');
      runScript := False;
    end;

  end;

  postExit;
end.