--アイテム1号の高さ算出Lua＠ロックマン２

--高さテキストを取得する
function get_height_str(DefaultHeight,Height,Visible,Arm)
	--アイテム1号が存在するとき
	if((Visible == 0x82 or Visible == 0xC2) and Arm == 0x9)then
		return string.format(" %03d",Height)
	--存在しないとき
	else
		return string.format("*%03d",DefaultHeight)
	end
end

--高さを取得する
function get_height(DefaultHeight,Height,Visible,Arm)
	--アイテム1号が存在するとき
	if((Visible == 0x82 or Visible == 0xC2) and Arm == 0x9)then
		return Height
	--存在しないとき
	else
		return DefaultHeight
	end
end

--上昇ヒントを取得する
function get_up(Seed,MaxFrame,Height)
	local UpText = ""
	for i = 0,MaxFrame,1 do
		Seed = Seed - 0x41
		if(Seed < 0)then
			UpText = UpText .. "|"
			Seed = Seed + 0x100
			Height = Height - 1
		else
			UpText = UpText .. "."
		end
	end
	return string.format("%s %d",UpText,Height)
end


--CSVを出力するか
local output_csv_flag = false

--CSVを出力する最大フレーム数
local max_csv_frame = 100

--シードごとのmax_csv_frameフレームの高さCSVを出力する
function output_csv(FileName,Seed,DefaultHeight,Height,Visible,Arm)

	local NowHeight = 0

	--アイテム1号が存在するとき
	if((Visible == 0x82 or Visible == 0xC2) and Arm == 0x9)then
		NowHeight = Height
	--存在しないとき
	else
		NowHeight = DefaultHeight
	end

	--出力
	fp = io.open (FileName,"w")

	--ヘッダ
	fp:write(" ,")
	for i= 0,max_csv_frame,1 do
		fp:write(string.format("%d,",i))
	end
	fp:write("\n")

	--シードごとの高さを出力
	format = ""
	for i = 0,255,1 do
		if(Seed == i)then
			format = "%d!,%s\n"
		else
			format = "%d,%s\n"
		end
		fp:write(string.format(format,i,get_height_csv(NowHeight,i)))
	end

	--閉じる
	fp:close()

	output_csv_flag = false
end

--シードに対応するmax_csv_frameフレーム分のCSVテキストを取得する
function get_height_csv(Height,Seed)
	height_csv = ""
	for i = 0,max_csv_frame,1 do
		Seed = Seed - 0x41
		if(Seed < 0)then
			Seed = Seed + 0x100
			Height = Height - 1
		end
		if(Height <= 0)then
			break
		end
		height_csv = height_csv .. Height .. ","
	end
	return height_csv
end


--何フレーム分ボタンを保存するか
local max_bakinp_frame = 20
--ボタンをしばらく押し続けているか、または一瞬押したかチェック
function holding_key(inp,bakinp,key)

	if((inp[key] == false or inp[key] == nil) and bakinp[2][key] == true)then
		return true
	end
	for i = 1,max_bakinp_frame,1 do
		if(bakinp[i][key]~=true)then
			return false
		end
	end
	return true
end

--何フレーム分上昇ヒントを表示するか
local up_display_frame = 4
--CSVセーブ時の文言表示
local output_msg_frame = false

gui.register(function()

	--現在装備中の武器
	local Arm = memory.readbyte(0xA9)

	--すべてのアイテム1号のデフォルトとなる高さ
	local DefaultHeight = memory.readbyte(0x4a0)

	--アイテム1号の高さ
	local Height = {}
	Height[1] = memory.readbyte(0x4a4)
	Height[2] = memory.readbyte(0x4a3)
	Height[3] = memory.readbyte(0x4a2)

	--シード
	local Seed = {}
	Seed[1] = memory.readbyte(0x4c4)
	Seed[2] = memory.readbyte(0x4c3)
	Seed[3] = memory.readbyte(0x4c2)

	--存在
	local Visible = {}
	Visible[1] = memory.readbyte(0x424)
	Visible[2] = memory.readbyte(0x423)
	Visible[3] = memory.readbyte(0x422)

	--高さ算出
	local Item1Height = {}
	Item1Height[1] = get_height_str(DefaultHeight,Height[1],Visible[1],Arm)
	Item1Height[2] = get_height_str(DefaultHeight,Height[2],Visible[2],Arm)
	Item1Height[3] = get_height_str(DefaultHeight,Height[3],Visible[3],Arm)

	--上昇ルール算出
	local Item1Up = {}
	Item1Up[1] = get_up(Seed[1],up_display_frame,get_height(DefaultHeight,Height[1],Visible[1],Arm))
	Item1Up[2] = get_up(Seed[2],up_display_frame,get_height(DefaultHeight,Height[2],Visible[2],Arm))
	Item1Up[3] = get_up(Seed[3],up_display_frame,get_height(DefaultHeight,Height[3],Visible[3],Arm))

	--出力
	gui.text(5,0, string.format("Item1->:Height($4C4-4C2) %df",up_display_frame))
	gui.text(5,10, string.format("1st->:%s(%03d) %s",Item1Height[1],Seed[1],Item1Up[1]))
	gui.text(5,20,string.format("2nd->:%s(%03d) %s",Item1Height[2],Seed[2],Item1Up[2]))
	gui.text(5,30,string.format("3rd->:%s(%03d) %s",Item1Height[3],Seed[3],Item1Up[3]))

	--CSV出力
	if(output_csv_flag == true)then
		output_csv("Item1_1st.csv",Seed[1],DefaultHeight,Height[1],Visible[1],Arm)
		output_csv("Item1_2nd.csv",Seed[2],DefaultHeight,Height[2],Visible[2],Arm)
		output_csv("Item1_3rd.csv",Seed[3],DefaultHeight,Height[3],Visible[3],Arm)
	end

	
	--入力の取得
	local inp = input.get()
	local input = inp

	--入力のバックアップ値初期化
	if(bakinp == nil)then
		bakinp = {}
	end
	for i = 1,max_bakinp_frame,1 do
		if(bakinp[i] == nil)then
			bakinp[i] = {}
		end
	end

	--ボタンのバックアップ
	for i = max_bakinp_frame,1,-1 do
		if(i == 1)then
			bakinp[1] = input
		else
			bakinp[i] = bakinp[i-1]
		end
	end


	--Sボタンを押したときCSV出力
	if(inp.S == true and (bakinp.S == nil or bakinp.S == false))then
		output_csv_flag = true
		output_msg_frame = movie.framecount()
	end

	--CSV出力したらしばらくの間メッセージ表示
	if(output_msg_frame ~= false)then
		if(movie.framecount() < (output_msg_frame + 60))then
			gui.text(5,40, "output csv file")
		end
	end

	--Pボタンを押したとき上昇ヒント表示増加
	if(holding_key(inp,bakinp,"P")) then
		up_display_frame = up_display_frame + 1
		if(up_display_frame > 40)then
			up_display_frame = 40
		end
	end
	
	--Mボタンを押したとき上昇ヒント表示減少
	if(holding_key(inp,bakinp,"O"))then
		up_display_frame = up_display_frame - 1
		if(up_display_frame < 0)then
			up_display_frame = 0
		end
	end

	--1stSeed+1
	if(holding_key(inp,bakinp,"Y"))then
		memory.writebyte(0x4c4,memory.readbyte(0x4c4)+0x01)
	end
	--1stSeed-1
	if(holding_key(inp,bakinp,"H"))then
		memory.writebyte(0x4c4,memory.readbyte(0x4c4)-0x01)
	end

	--2ndSeed+1
	if(holding_key(inp,bakinp,"U"))then
		memory.writebyte(0x4c3,memory.readbyte(0x4c3)+0x01)
	end
	--2ndSeed-1
	if(holding_key(inp,bakinp,"J"))then
		memory.writebyte(0x4c3,memory.readbyte(0x4c3)-0x01)
	end

	--3rdSeed+1
	if(holding_key(inp,bakinp,"I"))then
		memory.writebyte(0x4c2,memory.readbyte(0x4c2)+0x01)
	end
	--3rdSeed-1
	if(holding_key(inp,bakinp,"K"))then
		memory.writebyte(0x4c2,memory.readbyte(0x4c2)-0x01)
	end

end)


while true do
	emu.frameadvance()
end
