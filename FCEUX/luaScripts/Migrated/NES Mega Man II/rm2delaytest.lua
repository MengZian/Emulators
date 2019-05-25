-- ディレイスクロールテストスクリプト
-- 意図的にディレイスクロールを再現。セレクトで使うディレイスクロールを切り替え

local now_mode = 0;
local mode_list = {}
mode_list[0] = "NONE"	--なし
mode_list[1] = "PRE"	--前画面スクロール
mode_list[2] = "NEXT"	--次画面スクロール
mode_list[3] = "DEATH"	--ディレイ死、ディレイ梯子

local old_select = nil	--セレクト入力バックアップ
local select = nil	--セレクト入力


-- すべての命令実行に割り込み
-- TODO: 領域をしぼる、一括で処理しない？その他無駄な処理をしないような工夫
memory.registerexec(0x828b, 0x20, function(address)

	local pc = address -- memory.getregister("pc")
	local b1 = memory.readbyte(pc)

	-- 前画面スクロール
	if (pc == 0x828b and b1 == 0xA4) then
		
		if(now_mode == 1)then

			memory.setregister("a",0xff)

		elseif(now_mode == 3)then

			memory.setregister("a",0x00)

		end

	-- 次画面スクロールの判定
	elseif (pc == 0x82a2 and b1 == 0xa4) then
		
		--次画面スクロール
		if(now_mode == 2)then

			memory.setregister("a",0xff)

		--ディレイ死
		elseif(now_mode == 3)then
			
			memory.setregister("a",0x00)

		end

	end

end)

gui.register(function()
	local xadj, yadj = 0, 5
	gui.text(5+xadj,5+yadj, mode_list[now_mode])
end)



while true do
	local pad = joypad.get(1)
	select = pad.select

	if(old_select == false and select == true)then
		if(now_mode == 3)then
			now_mode = 0
		else
			now_mode = now_mode+1
		end
	end
	old_select = select

	emu.frameadvance()
end
