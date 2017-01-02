

require("OpenPredict")

local KMenu = Menu("Khazix", "Khazix")
KMenu:SubMenu("Combo", "Combo")
KMenu.Combo:Boolean("Q","Use Q",true)
KMenu.Combo:Boolean("W","Use W",true)
KMenu.Combo:Boolean("E","Use E",true)
KMenu.Combo:Boolean("R","Use R",true)
KMenu.Combo:Key("Combo1", "Combo Key", 32)

local WStats = {speed = 1700, width = 73, delay = 0.25, range = 1025}
local EStats = {speed = 2000, width = 75, delay = 0.25, range = 700}

if GetCastName(myHero,_E) == "KhazixELong" then            
    EStats.range = 900
end

local khaPassive = GotBuff(myHero,"KhazixPDamage")
local IsAA = false

OnProcessSpell(function(unit,spell)
    if unit == myHero then
    	if spell.name:lower():find("attack") then
        	IsAA = true
        end
    end
end)

OnProcessSpellComplete(function(unit,spell)
    if unit == myHero then
    	if spell.name:lower():find("attack") then
        	IsAA = false
       		if KMenu.Combo.Combo1:Value() and GetObjectType(spell.target) == Obj_AI_Hero then 
                local looksLikeHydraToMe
                local titan = GetItemSlot(myHero,3748)
                if GetItemSlot(myHero,3077) > 0 then
                    looksLikeHydraToMe = GetItemSlot(myHero,3077)
                elseif GetItemSlot(myHero,3074) > 0 then
                    looksLikeHydraToMe = GetItemSlot(myHero,3074)
                end
                if looksLikeHydraToMe ~= nil and looksLikeHydraToMe > 0 then
                    if CanUseSpell(myHero,looksLikeHydraToMe) == READY then
                        CastSpell(looksLikeHydraToMe)
                    end
                end
                if titan > 0 then
                    if CanUseSpell(myHero,titan) == READY then
                        CastSpell(titan)
                        DelayAction(function()
                            AttackUnit(spell.target)
                        end, 0.03)
                    end
                end
			end
        end
    end
end)
  
OnAnimation(function(unit,animation)
    if unit == myHero then
        --print(animation)
        if animation == "Run" then
      		IsAA = false
        end
      	if animation == "Evo2E" then
			EStats.range = 900
		end
    end
end)

-- go ingame and get the kha buff name :^)
OnUpdateBuff(function(unit,buff)
    if unit == myHero then
      --print(buff.Name)
      	if buff.Name == "KhazixPDamage" then
        	khaPassive = true
        end
    end
end)

OnRemoveBuff(function(unit,buff)
    if unit == myHero then
  	 --print(buff.Name) no, you did it already its "KhazixPDamage"
     	if buff.Name == "KhazixPDamage" then
        	khaPassive = false
        end
    end
end)


---ISOLATION ---
----------------

local iso = {}

local onLoop = Callback.Add("ObjectLoop", function(o) ObjectLoop(o) end)

DelayAction(function()
	Callback.Del("ObjectLoop",onLoop)
end,0.25)

function ObjectLoop(o)
	if GetDistance(GetOrigin(o)) < 3000 then
		if GetObjectBaseName(o):lower():find("khazix_base_q") then
			if GetObjectBaseName(o):lower():find("indicator.troy") then
				table.insert(iso, o)
			end
		end
	end
end

OnCreateObj(function(o)
	if GetDistance(o) < 3000 then
		if GetObjectBaseName(o):lower():find("khazix_base_q") then
			if GetObjectBaseName(o):lower():find("indicator.troy") then
				table.insert(iso, o)
			end
		end
	end
end)

OnDeleteObj(function(o)
	if GetDistance(o) < 3000 then
		if GetObjectBaseName(o):lower():find("khazix_base_q") then
			if GetObjectBaseName(o):lower():find("indicator.troy") then
				for i,v in pairs(iso) do
					if GetDistance(GetOrigin(v),GetOrigin(o)) < 10 then
						table.remove(iso,i)
					end
				end
			end
		end
	end
end)

function IsIsolated(unit)
	local isolation = false
	for i,v in pairs(iso) do
		if GetDistance(GetOrigin(unit),GetOrigin(v)) < 10 then
			isolation = true
		end
	end
	return isolation
end

----------------

local DPS = 0
local function GetQDMG(target)
	if IsIsolated(target) == true then
      	-- EVOLVED ISOLATION PHYSICAL DAMAGE: 91 / 123.5 / 156 / 188.5 / 221 + [10 - 180](based on level) (+ 260% Bonus AD)
		return CalcDamage(myHero,target, 58.5 + 32.5*GetCastLevel(myHero,_Q) + GetBonusDmg(myHero)*2.6 + 10*GetLevel(myHero), 0) 
	else
    	-- PHYSICAL DAMAGE: 70 / 95 / 120 / 145 / 170 (+ 120% Bonus AD) 
		return CalcDamage(myHero,target, 45 + 25*GetCastLevel(myHero,_Q) + GetBonusDmg(myHero)*1.2 , 0)
	end
end

OnDraw(function()
    local target = GetCurrentTarget()
    if ValidTarget(target, 1400) and GetCurrentHP(target) + GetDmgShield(target) <= DPS then
      	local hppos = GetHPBarPos(target) 
      	DrawText("Killable",22,hppos.x + 35,hppos.y+ 24,ARGB(255,135,219,129))
    end
end)

----------------

OnTick(function()

    local target = GetCurrentTarget()
    
    -- DAMAGE CALC --
    local qDMG = 0
    local wDMG = 0
    local eDMG = 0
    local aaDMG = CalcDamage(myHero,target,GetBaseDamage(myHero) + GetBonusDmg(myHero), 0)
    local passiveDMG = 0
    if khaPassive == true then
      	passiveDMG = CalcDamage(myHero,target, 0, (({[1]=15,[2]=20,[3]=25,[4]=35,[5]=45,[6]=55,[7]=65,[8]=75,[9]=85,[10]=95,[11]=110,[12]=125,[13]=140,[14]=150,[15]=160,[16]=170,[17]=180,[18]=190})[GetLevel(myHero)]) + GetBonusAP(myHero)*0.5)
    end
    if Ready(_Q) then
      qDMG = GetQDMG(target)
    end
    if Ready(_W) then
      	-- PHYSICAL DAMAGE: 80 / 110 / 140 / 170 / 200 (+ 100% Bonus AD) 
      	wDMG = CalcDamage(myHero,target, 50 + 30*GetCastLevel(myHero,_W) + GetBonusDmg(myHero) , 0 )
    end
    if Ready(_E) then
      	-- PHYSICAL DAMAGE: 65 / 100 / 135 / 170 / 205 (+ 20% Bonus AD)
      	eDMG = CalcDamage(myHero,target, 30 + 35*GetCastLevel(myHero,_E) + GetBonusDmg(myHero)*.2  , 0 )
    end
    DPS = qDMG + wDMG + eDMG + aaDMG + passiveDMG
    -----------------
    
	if KMenu.Combo.Combo1:Value() then
       	
      	local ghost = GetItemSlot(myHero,3142)
      	if ValidTarget(target,400) and ghost > 0 and Ready(ghost) then
        	CastSpell(ghost)
        end
    
		if KMenu.Combo.Q:Value() and Ready(_Q) and ValidTarget(target, GetCastRange(myHero,_Q) + GetHitBox(target)/2) then
        	if IsAA == false or IsIsolated(target) == true then
       			CastTargetSpell(target, _Q)
          	end
		end
    
   -- I would add here a check in how many enemies you jump in I dont think that you want to jump in into 5 enemies
      	-- GetDistance(myHero,target) > 325 
      	if KMenu.Combo.E:Value() and Ready(_E) and ValidTarget(target, EStats.range) and IsAA == false and GetDistance(myHero,target) > GetCastRange(myHero,_Q) + GetHitBox(target)/2 then
      		local EPred = GetCircularAOEPrediction(target, EStats)  
        	if EnemiesAround(EPred.castPos, 500) < 5 and AlliesAround(EPred.castPos, EStats.range) < EnemiesAround(EPred.castPos, 500) then
            	if EPred.hitChance >= 0.4 then
         			CastSkillShot(_E, EPred.castPos)
          	 	end
        	end
    
      
      	if KMenu.Combo.W:Value() and Ready(_W) and ValidTarget(target, WStats.range) and IsAA == false then
       		 local WPred = GetPrediction(target, WStats)
        	-- W has minnion collision :mCollision()
          	if WPred.hitChance >= 0.2 and not WPred:mCollision(1) then
      			CastSkillShot(_W, WPred.castPos)
            end
        end
      
        
        
        -- random numbers that I like to use | It will activate if your passive is off for the passive reset or if there are more than 2 enemies around you
        if KMenu.Combo.R:Value() and Ready(_R) and ValidTarget(target, 400) and ( ( khaPassive == false and GetCurrentHP(target) > GetQDMG(target) + DPS ) or EnemiesAround(GetOrigin(myHero), 500) > 2 ) and IsAA == false then
        	CastSpell(3)
        end
   end
end)
	
