--!nocheck
--=====================================================================
--  LUCXZZS HUB  ::  BLOX FRUITS RECOLOR
--  FIX: limite nao e mais cumulativo (nao trava mais depois de um tempo)
--  FIX: separacao estatico/dinamico + watchdog + rescan no respawn
--  NOVO: splash de inicializacao
--  v3 : FILTRO DE DONO REAL -> mundo/NPC vs efeito de player
--       + raio ajustavel + dump de debug
--=====================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LP = Players.LocalPlayer
if not LP then
	repeat task.wait(0.1) until Players.LocalPlayer
	LP = Players.LocalPlayer
end

local function log(...)
	print("[LUCXZZS HUB]", ...)
end

--=====================================================================
-- LIMPEZA
--=====================================================================
do
	local env = (getgenv and getgenv()) or _G
	if env.BFRecolor and env.BFRecolor.destroy then pcall(env.BFRecolor.destroy) end
	env.BFRecolor = nil

	local roots = {}
	local okc, cg = pcall(function() return game:GetService("CoreGui") end)
	if okc and cg then table.insert(roots, cg) end
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and typeof(h) == "Instance" then table.insert(roots, h) end
	end
	local pg = LP:FindFirstChildOfClass("PlayerGui")
	if pg then table.insert(roots, pg) end

	for _, r in ipairs(roots) do
		for _, nome in ipairs({ "BFRecolorUI", "LucxzzsSplash" }) do
			local g = r:FindFirstChild(nome)
			if g then pcall(function() g:Destroy() end) end
		end
	end
	log("limpeza ok")
end

--=====================================================================
-- MAIN
--=====================================================================
local function main()
	local cfg = {
		enabled = true,
		palette = "roxo",

		hueJitter   = 0.05,
		satJitter   = 0.10,
		valueJitter = 0.18,
		microJitter = 0.45,

		animate      = true,
		animateSpeed = 0.6,
		animateHue   = 0.015,
		animateValue = 0.06,

		sequenceMode = "flat",

		lightEmission  = 0.85,
		lightInfluence = 0.0,

		recolorParts         = true,
		recolorTexturedParts = false,
		recolorGui           = false,
		ignoreLocalCharacter = false,
		partMaterials = { Neon = true, ForceField = true, Glass = true },

		-- >>> v3: filtro
		-- "char"  = so dentro do meu personagem
		-- "near"  = meu personagem + raio  (padrao)
		-- "loose" = meu personagem + sem dono em qualquer lugar
		-- "all"   = tudo
		filterMode = "near",
		nearRadius = 20,

		maxDynamic    = 6000,
		maxStatic     = 30000,
		staticInterval = 0.25,

		rescanInterval = 2.5,
		worldRefresh   = 8,
	}

	local ignoreNames = {
		Hitbox = true, HitBox = true, Root = true,
		RootPart = true, CollisionBox = true,
	}

	local PALETTES = {
		roxo        = { tints = { Color3.fromRGB(150, 60, 255) }, spread = 1.0 },
		roxo_escuro = { tints = { Color3.fromRGB(90, 25, 160), Color3.fromRGB(55, 12, 105) }, spread = 1.0 },
		roxo_neon   = { tints = { Color3.fromRGB(180, 80, 255) }, spread = 1.2 },
		violeta     = { tints = { Color3.fromRGB(138, 43, 226) }, spread = 1.0 },
		ametista    = { tints = { Color3.fromRGB(153, 102, 204), Color3.fromRGB(118, 70, 180) }, spread = 1.0 },
		sombrio     = { tints = { Color3.fromRGB(45, 20, 75), Color3.fromRGB(22, 8, 40) }, spread = 1.1 },
		vermelho    = { tints = { Color3.fromRGB(255, 45, 45) }, spread = 1.0 },
		sangue      = { tints = { Color3.fromRGB(150, 12, 18), Color3.fromRGB(105, 6, 10) }, spread = 1.1 },
		carmim      = { tints = { Color3.fromRGB(200, 25, 60) }, spread = 1.0 },
		vinho       = { tints = { Color3.fromRGB(110, 15, 40) }, spread = 1.0 },
		rosa        = { tints = { Color3.fromRGB(255, 105, 180) }, spread = 1.0 },
		magenta     = { tints = { Color3.fromRGB(255, 0, 200) }, spread = 1.1 },
		pink_neon   = { tints = { Color3.fromRGB(255, 60, 190) }, spread = 1.2 },
		laranja     = { tints = { Color3.fromRGB(255, 120, 25) }, spread = 1.0 },
		ambar       = { tints = { Color3.fromRGB(255, 180, 45) }, spread = 0.9 },
		dourado     = { tints = { Color3.fromRGB(255, 200, 70), Color3.fromRGB(230, 160, 40) }, spread = 0.9 },
		amarelo     = { tints = { Color3.fromRGB(255, 235, 70) }, spread = 0.9 },
		verde       = { tints = { Color3.fromRGB(45, 220, 85) }, spread = 1.0 },
		esmeralda   = { tints = { Color3.fromRGB(20, 170, 100) }, spread = 1.0 },
		lima        = { tints = { Color3.fromRGB(150, 255, 60) }, spread = 1.1 },
		veneno      = { tints = { Color3.fromRGB(130, 255, 45), Color3.fromRGB(85, 195, 30) }, spread = 1.1 },
		ciano       = { tints = { Color3.fromRGB(0, 235, 235) }, spread = 1.0 },
		turquesa    = { tints = { Color3.fromRGB(60, 220, 200) }, spread = 1.0 },
		azul        = { tints = { Color3.fromRGB(60, 130, 255) }, spread = 1.0 },
		azul_gelo   = { tints = { Color3.fromRGB(150, 220, 255) }, spread = 0.9 },
		indigo      = { tints = { Color3.fromRGB(70, 70, 230) }, spread = 1.0 },
		branco      = { tints = { Color3.fromRGB(245, 245, 255) }, spread = 0.7 },
		prata       = { tints = { Color3.fromRGB(200, 205, 225) }, spread = 0.8 },
		preto       = { tints = { Color3.fromRGB(35, 35, 45), Color3.fromRGB(14, 14, 20) }, spread = 1.0 },
		carvao      = { tints = { Color3.fromRGB(65, 65, 80) }, spread = 1.0 },
		lua         = { tints = { Color3.fromRGB(205, 215, 255), Color3.fromRGB(160, 175, 240) }, spread = 0.8 },
		fogo        = { tints = { Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 140, 30), Color3.fromRGB(255, 60, 20) }, spread = 1.0 },
		magma       = { tints = { Color3.fromRGB(255, 100, 10), Color3.fromRGB(220, 40, 10), Color3.fromRGB(150, 20, 10) }, spread = 1.0 },
		gelo        = { tints = { Color3.fromRGB(185, 235, 255), Color3.fromRGB(120, 200, 255), Color3.fromRGB(90, 160, 240) }, spread = 0.9 },
		haki        = { tints = { Color3.fromRGB(70, 40, 130), Color3.fromRGB(35, 20, 60), Color3.fromRGB(20, 20, 30) }, spread = 1.1 },
		vazio       = { tints = { Color3.fromRGB(15, 10, 25), Color3.fromRGB(42, 26, 62) }, spread = 1.0 },
		arco_iris   = { tints = { Color3.fromRGB(255,60,60), Color3.fromRGB(255,180,40), Color3.fromRGB(60,255,120), Color3.fromRGB(60,180,255), Color3.fromRGB(180,80,255) }, spread = 1.0, rainbow = true },
	}

	local paletteOrder = {}
	for k in pairs(PALETTES) do paletteOrder[#paletteOrder + 1] = k end
	table.sort(paletteOrder)

	--=================================================================
	-- HELPERS
	--=================================================================
	local function frac(x) return x - math.floor(x) end
	local function rand01(a, b) return frac(math.sin(a * 12.9898 + b * 78.233) * 43758.5453) end

	local function resolvePalette(name)
		if type(name) ~= "string" then return nil end
		return PALETTES[(name:lower():gsub("%s+", "_"))]
	end

	local function notify(text)
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Lucxzzs Hub", Text = text, Duration = 2,
			})
		end)
	end

	local function vary(color, seed, salt, amount)
		amount = amount or 1
		local h, s, v = color:ToHSV()
		h = (h + (rand01(seed, salt) - 0.5) * cfg.hueJitter * amount) % 1
		s = math.clamp(s + (rand01(seed, salt + 3.7) - 0.5) * cfg.satJitter * amount, 0, 1)
		v = math.clamp(v + (rand01(seed, salt + 7.1) - 0.5) * cfg.valueJitter * amount, 0.05, 1)
		return Color3.fromHSV(h, s, v)
	end

	--=================================================================
	-- >>> v3 :: DETECCAO DE MUNDO (mapa / NPC)
	--=================================================================
	local worldRoots = setmetatable({}, { __mode = "k" })

	local function looksLikeWorld(c)
		if c == workspace.Terrain then return true end
		if c:IsA("BasePart") then return c.Anchored end
		if not (c:IsA("Model") or c:IsA("Folder")) then return false end

		-- personagem (player ou NPC) nao e raiz de mapa
		if c:FindFirstChildOfClass("Humanoid") then return false end
		if Players:GetPlayerFromCharacter(c) then return false end

		local parts, anchored = 0, 0
		local ok, desc = pcall(function() return c:GetDescendants() end)
		if not ok then return false end
		for i = 1, #desc do
			local d = desc[i]
			if d:IsA("BasePart") then
				parts += 1
				if d.Anchored then anchored += 1 end
			end
			if parts >= 600 then break end
		end
		if parts < 8 then return false end
		return (anchored / parts) >= 0.7
	end

	local function refreshWorld()
		local kids = workspace:GetChildren()
		for i = 1, #kids do
			local c = kids[i]
			if not worldRoots[c] and looksLikeWorld(c) then
				worldRoots[c] = true
			end
		end
	end

	--=================================================================
	-- >>> v3 :: RESOLUCAO DE DONO
	--  niveis: "char" (certeza) > "attr" > "name"
	--=================================================================
	local OWNER_ATTRS = {
		"Owner", "owner", "Player", "player", "Creator", "creator",
		"Shooter", "shooter", "UserId", "userId", "OwnerId", "ownerId",
		"PlayerName", "playerName", "Username", "username",
	}

	local function containsToken(hay, needle)
		local init = 1
		while true do
			local s, e = hay:find(needle, init, true)
			if not s then return false end
			local before = s > 1 and hay:sub(s - 1, s - 1) or nil
			local after  = e < #hay and hay:sub(e + 1, e + 1) or nil
			local okB = (not before) or not before:match("%w")
			local okA = (not after)  or not after:match("%w")
			if okB and okA then return true end
			init = e + 1
		end
	end

	local function toPlayer(v)
		local tv = typeof(v)
		if tv == "Instance" then
			if v:IsA("Player") then return v end
			local ok, p = pcall(Players.GetPlayerFromCharacter, Players, v)
			if ok and p then return p end
			return nil
		elseif tv == "string" then
			local p = Players:FindFirstChild(v)
			if p and p:IsA("Player") then return p end
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.DisplayName == v then return plr end
			end
			return nil
		elseif tv == "number" then
			return Players:GetPlayerByUserId(v)
		end
		return nil
	end

	-- nivel "char" = ancestral e' literalmente um personagem
	local function ownerFromCharacter(obj)
		local cur, depth = obj, 0
		while cur and cur ~= workspace and depth < 15 do
			if cur:IsA("Model") then
				local ok, p = pcall(Players.GetPlayerFromCharacter, Players, cur)
				if ok and p then return p end
			end
			cur = cur.Parent
			depth += 1
		end
		return nil
	end

	local function ownerFromMeta(obj)
		local cur, depth = obj, 0
		while cur and cur ~= workspace and depth < 5 do
			for i = 1, #OWNER_ATTRS do
				local ok, v = pcall(cur.GetAttribute, cur, OWNER_ATTRS[i])
				if ok and v ~= nil then
					local p = toPlayer(v)
					if p then return p end
				end
			end
			local kids = cur:GetChildren()
			for i = 1, #kids do
				local ch = kids[i]
				if ch:IsA("ObjectValue") and ch.Value and ch.Value:IsA("Player") then
					return ch.Value
				end
			end
			cur = cur.Parent
			depth += 1
		end

		local partes, d = {}, 0
		cur = obj
		while cur and cur ~= workspace and d < 4 do
			partes[#partes + 1] = cur.Name
			cur = cur.Parent
			d += 1
		end
		local hay = table.concat(partes, "|")
		local melhor, tam = nil, 0
		for _, plr in ipairs(Players:GetPlayers()) do
			local cands = { plr.Name }
			if plr.DisplayName and plr.DisplayName ~= plr.Name then
				cands[#cands + 1] = plr.DisplayName
			end
			for i = 1, #cands do
				local n = cands[i]
				if #n >= 3 and #n > tam and containsToken(hay, n) then
					melhor, tam = plr, #n
				end
			end
		end
		return melhor
	end

	local function resolveOwner(obj)
		local p = ownerFromCharacter(obj)
		if p then return p, "char" end
		p = ownerFromMeta(obj)
		if p then return p, "meta" end
		return nil, nil
	end

	--=================================================================
	-- >>> v3 :: CLASSIFICACAO
	--=================================================================
	local function isWorldObject(obj)
		local cur, depth = obj, 0
		while cur and cur ~= workspace and depth < 15 do
			if worldRoots[cur] then return true end
			if cur:IsA("Model") then
				if cur:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(cur) then
					return true
				end
			end
			cur = cur.Parent
			depth += 1
		end
		return false
	end

	local function inRadius(obj)
		local char = LP.Character
		if not char then return false end
		local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
		if not root then return false end
		local pos = root.Position

		local function distOf(o)
			if o:IsA("BasePart") then
				local ok, d = pcall(function() return (o.Position - pos).Magnitude end)
				return ok and d or nil
			end
			if o:IsA("Model") then
				local ok, cf = pcall(function() return o:GetPivot() end)
				if ok then return (cf.Position - pos).Magnitude end
			end
			return nil
		end

		local d = distOf(obj)
		if d then return d <= cfg.nearRadius end

		local cur, depth = obj.Parent, 0
		while cur and cur ~= workspace and depth < 6 do
			d = distOf(cur)
			if d then return d <= cfg.nearRadius end
			cur = cur.Parent
			depth += 1
		end
		return false
	end

	-- retorna (permitido, dono, motivo)
	local function ownerAllowed(obj)
		local dono, nivel = resolveOwner(obj)

		if dono == LP then return true, LP, "meu" end
		if dono and dono ~= LP then return false, dono, "outro:" .. dono.Name end

		if isWorldObject(obj) then return true, nil, "mundo" end

		if cfg.filterMode == "all" then return true, nil, "modo:all" end
		if cfg.filterMode == "loose" then return true, nil, "modo:loose" end
		if cfg.filterMode == "char" then return false, nil, "fora-do-boneco" end

		if inRadius(obj) then return true, nil, "perto" end
		return false, nil, "longe"
	end

	--=================================================================
	-- MOTOR
	--=================================================================
	local GUI_ROOT

	local SEQ_PROPS = {
		ParticleEmitter = { "Color" },
		Beam            = { "Color" },
		Trail           = { "Color" },
	}

	local COL_PROPS = {
		PointLight        = { "Color" },
		SpotLight         = { "Color" },
		SurfaceLight      = { "Color" },
		Fire              = { "Color", "SecondaryColor" },
		Smoke             = { "Color" },
		Sparkles          = { "Color", "SparkleColor" },
		Highlight         = { "FillColor", "OutlineColor" },
		Texture           = { "Color3", "Color" },
		Decal             = { "Color3", "Color" },
		SurfaceAppearance = { "Color", "Color3" },
		ForceField        = { "Color" },
		SelectionBox      = { "Color3" },
	}

	local registry = setmetatable({}, { __mode = "k" })
	local list = {}
	local staticList = {}
	local counter = 0
	local running = true
	local lastPrune = 0
	local pending = {}
	local stats = { mine = 0, other = 0, world = 0, near = 0, blocked = 0 }

	local function kindOf(obj)
		if GUI_ROOT and obj:IsDescendantOf(GUI_ROOT) then return nil end

		local c = obj.ClassName
		local s = SEQ_PROPS[c]
		if s then return "seq", s end
		local p = COL_PROPS[c]
		if p then return "color", p end

		if cfg.recolorGui then
			if c == "TextLabel" or c == "TextButton" then return "color", { "TextColor3" } end
			if c == "ImageLabel" or c == "ImageButton" then return "color", { "ImageColor3" } end
		end

		if obj:IsA("BasePart") then
			if obj:IsA("Terrain") then return nil end
			if not cfg.recolorParts then return nil end
			if ignoreNames[obj.Name] then return nil end
			if cfg.ignoreLocalCharacter and LP.Character and obj:IsDescendantOf(LP.Character) then return nil end
			if cfg.partMaterials[obj.Material.Name] then return "color", { "Color" } end
			if cfg.recolorTexturedParts
				and (obj:FindFirstChildOfClass("Texture") or obj:FindFirstChildOfClass("Decal")) then
				return "color", { "Color" }
			end
		end
		return nil
	end

	local function isStaticObj(obj)
		if isWorldObject(obj) then return true end
		if obj:IsA("BasePart") and not obj.Anchored then return false end
		if LP.Character and obj:IsDescendantOf(LP.Character) then return false end
		if not obj:IsA("BasePart") then
			local c = obj.ClassName
			if c == "Texture" or c == "Decal" or c == "SurfaceAppearance" or c == "SelectionBox" then
				return true
			end
		end
		return true
	end

	local function targetColor(rec)
		local pal = resolvePalette(cfg.palette) or PALETTES.roxo
		local tints = pal.tints
		local tint = tints[((rec.tintIndex - 1) % #tints) + 1]
		local c = vary(tint, rec.seed, 0, pal.spread or 1)

		if cfg.animate then
			local t = os.clock() * cfg.animateSpeed
			local h, s, v = c:ToHSV()
			h = (h + math.sin(t + rec.seed * 0.37) * cfg.animateHue) % 1
			v = math.clamp(v + math.sin(t * 1.31 + rec.seed * 0.11) * cfg.animateValue, 0, 1)
			c = Color3.fromHSV(h, s, v)
		end

		if pal.rainbow then
			local _, s, v = c:ToHSV()
			c = Color3.fromHSV((os.clock() * 0.12 + rec.seed * 0.03) % 1, math.max(s, 0.85), v)
		end
		return c
	end

	local function tintFromBase(orig, base)
		local _, _, ov = orig:ToHSV()
		local bh, bs = base:ToHSV()
		return Color3.fromHSV(bh, bs, math.clamp(ov, 0.22, 1))
	end

	local function recolorSequence(seq, base, rec)
		local kps = seq.Keypoints
		local n = #kps
		if n == 0 then return seq end
		if n == 1 then
			return ColorSequence.new(
				ColorSequenceKeypoint.new(0, base),
				ColorSequenceKeypoint.new(1, vary(base, rec.seed, 9.1, cfg.microJitter))
			)
		end
		local out = table.create(n)
		if cfg.sequenceMode == "tint" then
			for i = 1, n do
				out[i] = ColorSequenceKeypoint.new(kps[i].Time, tintFromBase(kps[i].Value, base))
			end
		else
			for i = 1, n do
				out[i] = ColorSequenceKeypoint.new(kps[i].Time, vary(base, rec.seed, i * 9.13, cfg.microJitter))
			end
		end
		return ColorSequence.new(out)
	end

	local function applyRecord(rec)
		local obj = rec.obj
		if not obj or not obj.Parent then return end
		local base = targetColor(rec)

		for i = 1, #rec.props do
			local prop = rec.props[i]
			if rec.kind == "seq" then
				local ok, seq = pcall(function() return obj[prop] end)
				if ok and typeof(seq) == "ColorSequence" then
					obj[prop] = recolorSequence(seq, base, rec)
				end
			else
				local ok, cur = pcall(function() return obj[prop] end)
				if ok and typeof(cur) == "Color3" then
					obj[prop] = vary(base, rec.seed, i * 4.4, 0.5)
				end
			end
		end

		if cfg.lightEmission > 0
			and (obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail")) then
			obj.LightEmission = cfg.lightEmission
			obj.LightInfluence = cfg.lightInfluence
		end
	end

	local function rebuildList()
		local nd, ns = {}, {}
		for _, rec in pairs(registry) do
			if rec.obj and rec.obj.Parent then
				if rec.static then
					ns[#ns + 1] = rec
				else
					nd[#nd + 1] = rec
				end
			end
		end
		list = nd
		staticList = ns
	end

	local function register(obj)
		if registry[obj] then return "ok" end

		local kind, props = kindOf(obj)
		if not kind then return "skip" end

		local static = isStaticObj(obj)

		local allowed, dono, motivo = ownerAllowed(obj)
		if not allowed then
			if dono then
				stats.other += 1
				return "skip"
			end
			stats.blocked += 1
			return "wait"
		end

		if dono == LP then
			stats.mine += 1
		elseif motivo == "mundo" then
			stats.world += 1
		else
			stats.near += 1
		end

		local cap = static and cfg.maxStatic or cfg.maxDynamic
		local alvo = static and staticList or list

		if #alvo >= cap then
			if os.clock() - lastPrune > 1 then
				lastPrune = os.clock()
				rebuildList()
				alvo = static and staticList or list
			end
			if #alvo >= cap then return "ok" end
		end

		local pal = resolvePalette(cfg.palette) or PALETTES.roxo
		local orig = {}
		local valid = {}

		for i = 1, #props do
			local p = props[i]
			local ok, v = pcall(function() return obj[p] end)
			if ok and (typeof(v) == "Color3" or typeof(v) == "ColorSequence") then
				valid[#valid + 1] = p
				orig[p] = v
			end
		end

		if #valid == 0 then return "ok" end

		counter += 1

		local rec = {
			obj = obj,
			kind = kind,
			props = valid,
			static = static,
			seed = counter * 0.7351 + (#obj.Name) * 0.191,
			tintIndex = math.random(1, #pal.tints),
			orig = orig,
		}

		if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
			rec.orig.LightEmission = obj.LightEmission
			rec.orig.LightInfluence = obj.LightInfluence
		end

		registry[obj] = rec
		if static then
			staticList[#staticList + 1] = rec
		else
			list[#list + 1] = rec
		end

		if cfg.enabled then pcall(applyRecord, rec) end
		return "ok"
	end

	local failCount = 0
	local function safeRegister(obj)
		local ok, status = pcall(register, obj)
		if not ok then
			if failCount < 6 then
				failCount += 1
				warn("[LUCXZZS] register falhou: " .. tostring(obj) .. " -> " .. tostring(status))
			end
			return "skip"
		end
		return status
	end

	local function scanRoot(root)
		local ok, desc = pcall(function() return root:GetDescendants() end)
		if not ok then return end
		for i = 1, #desc do safeRegister(desc[i]) end
	end

	local function restoreAll()
		for obj, rec in pairs(registry) do
			if obj.Parent then
				for prop, val in pairs(rec.orig) do
					pcall(function() obj[prop] = val end)
				end
			end
		end
	end

	local function reapplyAll()
		for i = 1, #list do pcall(applyRecord, list[i]) end
		for i = 1, #staticList do pcall(applyRecord, staticList[i]) end
	end

	local function resetAll()
		restoreAll()
		registry = setmetatable({}, { __mode = "k" })
		list = {}
		staticList = {}
		stats.mine, stats.other, stats.world, stats.near, stats.blocked = 0, 0, 0, 0, 0
		for i = #pending, 1, -1 do pending[i] = nil end
		refreshWorld()
		scanRoot(workspace)
	end

	-- fila de retentativa (dono/posicao pode resolver depois)
	task.spawn(function()
		while running do
			task.wait(0.12)
			local n = #pending
			if n > 0 then
				local keep = {}
				for i = 1, n do
					local e = pending[i]
					local obj = e.obj
					if obj and obj.Parent and not registry[obj] then
						if e.tries < 12 then
							local st = safeRegister(obj)
							if st == "wait" then
								e.tries += 1
								keep[#keep + 1] = e
							end
						end
					end
				end
				pending = keep
			end
		end
	end)

	--=================================================================
	-- TEMA / UI HELPERS
	--=================================================================
	local theme = {
		bg     = Color3.fromRGB(13, 13, 19),
		panel  = Color3.fromRGB(21, 21, 30),
		panel2 = Color3.fromRGB(27, 27, 38),
		track  = Color3.fromRGB(46, 46, 60),
		text   = Color3.fromRGB(232, 232, 244),
		sub    = Color3.fromRGB(148, 148, 170),
		accent = Color3.fromRGB(150, 60, 255),
	}

	local FONT_DISPLAY = Enum.Font.LuckiestGuy
	local FONT_BODY    = Enum.Font.Gotham
	local FONT_BOLD    = Enum.Font.GothamBold

	local function inst(class, props)
		local o = Instance.new(class)
		if props then
			for k, v in pairs(props) do o[k] = v end
		end
		return o
	end

	local accentTargets = {}
	local function accent(obj, prop, mult)
		accentTargets[#accentTargets + 1] = { obj = obj, prop = prop, mult = mult or 1 }
		return obj
	end

	local function previewColor()
		local pal = resolvePalette(cfg.palette) or PALETTES.roxo
		return pal.tints[1]
	end

	local function refreshAccent()
		local c = previewColor()
		theme.accent = c
		for _, t in ipairs(accentTargets) do
			if t.obj and t.obj.Parent then
				t.obj[t.prop] = Color3.new(c.R * t.mult, c.G * t.mult, c.B * t.mult)
			end
		end
	end

	local function fmt(v, dec)
		if dec == 0 then return tostring(math.floor(v + 0.5)) end
		return string.format("%." .. dec .. "f", v)
	end

	local setPalette, setCustomColor, refreshAccentRef

	local function setEnabled(state)
		cfg.enabled = state
		if state then
			reapplyAll()
			notify("LIGADO (" .. cfg.palette .. ")")
		else
			restoreAll()
			notify("DESLIGADO")
		end
	end

	setPalette = function(name, silent)
		local pal = resolvePalette(name)
		if not pal then return end
		cfg.palette = (name:lower():gsub("%s+", "_"))
		for _, rec in pairs(registry) do rec.tintIndex = math.random(1, #pal.tints) end
		if cfg.enabled then reapplyAll() end
		if refreshAccentRef then refreshAccentRef() end
		if not silent then notify("Cor: " .. cfg.palette) end
	end

	setCustomColor = function(r, g, b, live)
		PALETTES.custom = { tints = { Color3.fromRGB(r, g, b) }, spread = 1.0 }
		cfg.palette = "custom"
		if not live then
			for _, rec in pairs(registry) do rec.tintIndex = 1 end
		end
		if cfg.enabled then reapplyAll() end
		if refreshAccentRef then refreshAccentRef() end
	end

	--=================================================================
	-- DEBUG DUMP
	--=================================================================
	local function debugDump()
		refreshWorld()
		print("========== BF RECOLOR :: DEBUG ==========")
		print("modo:", cfg.filterMode, "| raio:", cfg.nearRadius, "| recolorParts:", cfg.recolorParts)
		print("raizes de mundo detectadas:")
		for k in pairs(worldRoots) do print("   ->", k:GetFullName()) end

		local n, tot = 0, 0
		local desc = workspace:GetDescendants()
		for i = 1, #desc do
			local d = desc[i]
			if kindOf(d) then
				tot += 1
				if n < 70 then
					n += 1
					local dono, nivel = resolveOwner(d)
					local ok, motivo = ownerAllowed(d)
					print(string.format("[%s] %s | dono=%s(%s) | mundo=%s | perto=%s | %s",
						ok and "OK " or "BLOQ",
						d:GetFullName(), d.ClassName,
						dono and dono.Name or "-", tostring(nivel),
						tostring(isWorldObject(d)), tostring(inRadius(d)),
						tostring(motivo)))
				end
			end
		end
		print("total de candidatos:", tot)
		print("=========================================")
	end

	--=================================================================
	-- CONTAINER
	--=================================================================
	local function getContainer(gui)
		local candidates = {}
		if type(gethui) == "function" then
			local ok, h = pcall(gethui)
			if ok and typeof(h) == "Instance" then table.insert(candidates, h) end
		end
		local okc, cg = pcall(function() return game:GetService("CoreGui") end)
		if okc and cg then table.insert(candidates, cg) end
		local pg = LP:FindFirstChildOfClass("PlayerGui")
		if pg then table.insert(candidates, pg) end

		for _, c in ipairs(candidates) do
			local ok = pcall(function() gui.Parent = c end)
			if ok and gui.Parent == c then return c end
		end
		return nil
	end

	--=================================================================
	-- SPLASH
	--=================================================================
	local function buildSplash(container)
		local sg = inst("ScreenGui", {
			Name = "LucxzzsSplash", ResetOnSpawn = false, IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 2000,
		})
		sg.Parent = container

		local bg = inst("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(6, 6, 10), BorderSizePixel = 0,
		})
		bg.Parent = sg

		local glow = inst("Frame", {
			Size = UDim2.new(0, 700, 0, 700), Position = UDim2.new(0.5, -350, 0.5, -350),
			BackgroundColor3 = previewColor(), BorderSizePixel = 0, BackgroundTransparency = 0.93,
		})
		inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = glow })
		glow.Parent = bg

		local holder = inst("Frame", {
			Size = UDim2.new(0, 420, 0, 112), BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -10), Parent = bg,
		})

		local shadow = inst("TextLabel", {
			Size = UDim2.new(1, 0, 0, 76), Position = UDim2.new(0, 5, 0, 5),
			BackgroundTransparency = 1, Font = FONT_DISPLAY, Text = "LUCXZZS HUB",
			TextColor3 = Color3.fromRGB(24, 8, 46), TextScaled = true, Parent = holder,
		})
		inst("UITextSizeConstraint", { MaxTextSize = 90, Parent = shadow })

		local title = inst("TextLabel", {
			Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1, Font = FONT_DISPLAY,
			Text = "LUCXZZS HUB", TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true, Parent = holder,
		})
		inst("UITextSizeConstraint", { MaxTextSize = 90, Parent = title })

		local grad = inst("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.45, previewColor()),
				ColorSequenceKeypoint.new(0.55, previewColor()),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			Parent = title,
		})

		local stroke = inst("UIStroke", { Color = Color3.fromRGB(12, 6, 22), Thickness = 3, Parent = title })

		local sub = inst("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0, 78),
			BackgroundTransparency = 1, Font = FONT_BOLD,
			Text = "BLOX FRUITS   -   RECOLOR DE EFEITOS",
			TextColor3 = theme.sub, TextSize = 11, Parent = holder,
		})

		local line = inst("Frame", {
			Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0.5, 0, 0, 98),
			AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = previewColor(), BorderSizePixel = 0,
		})
		inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
		line.Parent = holder

		local barBg = inst("Frame", {
			Size = UDim2.new(0, 240, 0, 4), Position = UDim2.new(0.5, 0, 0, 130),
			AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.fromRGB(34, 34, 46), BorderSizePixel = 0,
		})
		inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barBg })
		barBg.Parent = bg

		local barFill = inst("Frame", {
			Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = previewColor(), BorderSizePixel = 0,
		})
		inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barFill })
		barFill.Parent = barBg

		local tag = inst("TextLabel", {
			Size = UDim2.new(0, 300, 0, 14), Position = UDim2.new(0.5, -150, 1, -40),
			BackgroundTransparency = 1, Font = FONT_BODY, Text = "carregando modulos...",
			TextColor3 = Color3.fromRGB(90, 90, 110), TextSize = 10, Parent = bg,
		})

		holder.Size = UDim2.new(0, 380, 0, 100)
		TweenService:Create(holder, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 560, 0, 150),
		}):Play()
		TweenService:Create(line, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 320, 0, 2),
		}):Play()
		TweenService:Create(barFill, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 1, 0),
		}):Play()

		task.spawn(function()
			while sg.Parent do
				grad.Offset = Vector2.new(-1.2, 0)
				local t = TweenService:Create(grad, TweenInfo.new(1.3, Enum.EasingStyle.Linear), {
					Offset = Vector2.new(1.2, 0),
				})
				t:Play()
				t.Completed:Wait()
				task.wait(0.2)
			end
		end)

		task.delay(1.1, function() if tag.Parent then tag.Text = "aplicando paleta..." end end)
		task.delay(2.0, function() if tag.Parent then tag.Text = "pronto" end end)

		task.delay(2.3, function()
			local alvos = {
				{ bg, "BackgroundTransparency", 1 }, { title, "TextTransparency", 1 },
				{ shadow, "TextTransparency", 1 }, { sub, "TextTransparency", 1 },
				{ tag, "TextTransparency", 1 }, { line, "BackgroundTransparency", 1 },
				{ barBg, "BackgroundTransparency", 1 }, { barFill, "BackgroundTransparency", 1 },
				{ glow, "BackgroundTransparency", 1 }, { stroke, "Transparency", 1 },
			}
			for _, a in ipairs(alvos) do
				TweenService:Create(a[1], TweenInfo.new(0.45), { [a[2]] = a[3] }):Play()
			end
			task.delay(0.55, function() pcall(function() sg:Destroy() end) end)
		end)

		return sg
	end

	--=================================================================
	-- UI PRINCIPAL
	--=================================================================
	local function buildUI()
		local gui = inst("ScreenGui", {
			Name = "BFRecolorUI", ResetOnSpawn = false, IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
		})
		gui.Parent = getContainer(gui)
		gui.Enabled = true
		GUI_ROOT = gui

		local main = inst("Frame", {
			Name = "Main", Size = UDim2.new(0, 520, 0, 400),
			Position = UDim2.new(0.5, -260, 0.5, -200),
			BackgroundColor3 = theme.bg, BorderSizePixel = 0,
		})
		inst("UICorner", { CornerRadius = UDim.new(0, 10), Parent = main })
		inst("UIStroke", { Color = theme.track, Thickness = 1, Parent = main })
		main.Parent = gui

		local header = inst("Frame", {
			Name = "Header", Size = UDim2.new(1, 0, 0, 42),
			BackgroundColor3 = theme.panel, BorderSizePixel = 0,
		})
		inst("UICorner", { CornerRadius = UDim.new(0, 10), Parent = header })
		inst("Frame", {
			Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10),
			BackgroundColor3 = theme.panel, BorderSizePixel = 0, Parent = header,
		})
		header.Parent = main

		local dot = inst("Frame", {
			Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 14, 0.5, -5),
			BackgroundColor3 = theme.accent, BorderSizePixel = 0, Parent = header,
		})
		inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		accent(dot, "BackgroundColor3", 1)

		local brand = inst("TextLabel", {
			Size = UDim2.new(0, 200, 0, 22), Position = UDim2.new(0, 32, 0, 6),
			BackgroundTransparency = 1, Font = FONT_DISPLAY, Text = "LUCXZZS HUB",
			TextColor3 = theme.text, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
		})

		local brandGrad = inst("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, previewColor()),
			}),
			Parent = brand,
		})

		inst("TextLabel", {
			Size = UDim2.new(0, 200, 0, 10), Position = UDim2.new(0, 33, 0, 27),
			BackgroundTransparency = 1, Font = FONT_BOLD, Text = "BLOX FRUITS RECOLOR",
			TextColor3 = theme.sub, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
		})

		local function headerButton(text, xOff, onClick)
			local b = inst("TextButton", {
				Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, xOff, 0.5, -12),
				BackgroundColor3 = theme.panel2, BorderSizePixel = 0, Font = FONT_BOLD,
				Text = text, TextColor3 = theme.sub, TextSize = 13, AutoButtonColor = false, Parent = header,
			})
			inst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
			b.MouseEnter:Connect(function() b.TextColor3 = theme.text end)
			b.MouseLeave:Connect(function() b.TextColor3 = theme.sub end)
			if onClick then b.MouseButton1Click:Connect(onClick) end
			return b
		end

		local minBtn = headerButton("-", -62)
		headerButton("X", -32, function() gui.Enabled = false end)

		local dragging, dragStart, startPos
		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		local body = inst("Frame", {
			Size = UDim2.new(1, -20, 1, -54), Position = UDim2.new(0, 10, 0, 48),
			BackgroundTransparency = 1, Parent = main,
		})

		minBtn.MouseButton1Click:Connect(function()
			body.Visible = not body.Visible
			main.Size = body.Visible and UDim2.new(0, 520, 0, 400) or UDim2.new(0, 520, 0, 48)
		end)

		local left = inst("Frame", {
			Size = UDim2.new(0, 244, 1, 0), BackgroundColor3 = theme.panel,
			BorderSizePixel = 0, Parent = body,
		})
		inst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = left })

		inst("TextLabel", {
			Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 12, 0, 8),
			BackgroundTransparency = 1, Font = FONT_BOLD, Text = "PALETAS",
			TextColor3 = theme.sub, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = left,
		})

		local palScroll = inst("ScrollingFrame", {
			Size = UDim2.new(1, -16, 1, -38), Position = UDim2.new(0, 8, 0, 30),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			ScrollBarImageColor3 = theme.track, CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = left,
		})
		inst("UIGridLayout", {
			CellSize = UDim2.new(0, 112, 0, 24), CellPadding = UDim2.new(0, 4, 0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder, Parent = palScroll,
		})

		local activePalBtn
		local palButtons = {}

		local function makePalButton(key)
			local pal = PALETTES[key]
			local btn = inst("TextButton", {
				BackgroundColor3 = theme.panel2, BorderSizePixel = 0,
				AutoButtonColor = false, Text = "", Parent = palScroll,
			})
			inst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
			local stroke = inst("UIStroke", {
				Color = theme.track, Thickness = 1, Transparency = 0.5, Parent = btn,
			})
			local sw = inst("Frame", {
				Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 7, 0.5, -5),
				BackgroundColor3 = pal.tints[1], BorderSizePixel = 0, Parent = btn,
			})
			inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sw })
			inst("TextLabel", {
				Size = UDim2.new(1, -26, 1, 0), Position = UDim2.new(0, 22, 0, 0),
				BackgroundTransparency = 1, Font = FONT_BODY, Text = key:gsub("_", " "):upper(),
				TextColor3 = theme.sub, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
			})

			btn.MouseEnter:Connect(function() btn.BackgroundColor3 = theme.track end)
			btn.MouseLeave:Connect(function() btn.BackgroundColor3 = theme.panel2 end)
			btn.MouseButton1Click:Connect(function()
				setPalette(key)
				if activePalBtn and activePalBtn ~= btn then
					local s = activePalBtn:FindFirstChildOfClass("UIStroke")
					if s then s.Color = theme.track; s.Transparency = 0.5 end
				end
				activePalBtn = btn
				stroke.Color = previewColor()
				stroke.Transparency = 0
			end)
			return btn, stroke
		end

		for _, key in ipairs(paletteOrder) do
			local b, s = makePalButton(key)
			palButtons[key] = { btn = b, stroke = s }
		end
		activePalBtn = palButtons[cfg.palette] and palButtons[cfg.palette].btn
		if activePalBtn then
			local s = activePalBtn:FindFirstChildOfClass("UIStroke")
			if s then s.Color = previewColor(); s.Transparency = 0 end
		end

		local right = inst("ScrollingFrame", {
			Size = UDim2.new(1, -256, 1, 0), Position = UDim2.new(0, 256, 0, 0),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			ScrollBarImageColor3 = theme.track, CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = body,
		})
		inst("UIListLayout", {
			Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right,
		})

		local order = 0
		local function nextOrder()
			order += 1
			return order
		end

		local function section(text)
			inst("TextLabel", {
				Size = UDim2.new(1, -8, 0, 18), BackgroundTransparency = 1, Font = FONT_BOLD,
				Text = text, TextColor3 = theme.sub, TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(), Parent = right,
			})
		end

		local function makeToggle(label, value, onChange)
			local holder = inst("Frame", {
				Size = UDim2.new(1, -8, 0, 26), BackgroundTransparency = 1,
				LayoutOrder = nextOrder(), Parent = right,
			})
			inst("TextLabel", {
				Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1, Font = FONT_BODY,
				Text = label, TextColor3 = theme.text, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
			})
			local sw = inst("Frame", {
				Size = UDim2.new(0, 34, 0, 18), Position = UDim2.new(1, -34, 0.5, -9),
				BackgroundColor3 = theme.track, BorderSizePixel = 0, Parent = holder,
			})
			inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sw })
			local knob = inst("Frame", {
				Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 2, 0.5, -7),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = sw,
			})
			inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

			local state = value
			local function render(anim)
				local goal = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
				local col = state and previewColor() or theme.track
				if anim then
					TweenService:Create(knob, TweenInfo.new(0.15), { Position = goal }):Play()
					TweenService:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = col }):Play()
				else
					knob.Position = goal
					sw.BackgroundColor3 = col
				end
			end
			render(false)

			local btn = inst("TextButton", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = holder,
			})
			btn.MouseButton1Click:Connect(function()
				state = not state
				render(true)
				onChange(state)
			end)
		end

		local function makeSlider(label, min, max, value, dec, onChange)
			local holder = inst("Frame", {
				Size = UDim2.new(1, -8, 0, 34), BackgroundTransparency = 1,
				LayoutOrder = nextOrder(), Parent = right,
			})
			inst("TextLabel", {
				Size = UDim2.new(1, -60, 0, 14), BackgroundTransparency = 1, Font = FONT_BODY,
				Text = label, TextColor3 = theme.text, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
			})
			local valLbl = inst("TextLabel", {
				Size = UDim2.new(0, 56, 0, 14), Position = UDim2.new(1, -56, 0, 0),
				BackgroundTransparency = 1, Font = FONT_BOLD, Text = "", TextColor3 = theme.sub,
				TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = holder,
			})
			local bar = inst("Frame", {
				Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0, 24),
				BackgroundColor3 = theme.track, BorderSizePixel = 0, Parent = holder,
			})
			inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
			local fill = inst("Frame", {
				Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = theme.accent,
				BorderSizePixel = 0, Parent = bar,
			})
			inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
			accent(fill, "BackgroundColor3", 1)

			local knob = inst("Frame", {
				Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0, ZIndex = 2, Parent = bar,
			})
			inst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

			local cur = value
			local function set(v, fire)
				cur = math.clamp(v, min, max)
				local a = (cur - min) / (max - min)
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				valLbl.Text = fmt(cur, dec)
				if fire then onChange(cur) end
			end
			set(cur, false)

			local isDragging = false
			local function fromX(x)
				local rel = (x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X)
				set(min + rel * (max - min), true)
			end
			holder.Active = true
			holder.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					isDragging = true
					fromX(input.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch) then
					fromX(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					isDragging = false
				end
			end)
		end

		local function makeButton(label, onClick)
			local b = inst("TextButton", {
				Size = UDim2.new(1, -8, 0, 28), BackgroundColor3 = theme.panel2,
				BorderSizePixel = 0, Font = FONT_BOLD, Text = label, TextColor3 = theme.text,
				TextSize = 12, AutoButtonColor = false, LayoutOrder = nextOrder(), Parent = right,
			})
			inst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = b })
			local stroke = inst("UIStroke", { Color = theme.track, Thickness = 1, Transparency = 0.5, Parent = b })
			b.MouseEnter:Connect(function() stroke.Color = previewColor(); stroke.Transparency = 0 end)
			b.MouseLeave:Connect(function() stroke.Color = theme.track; stroke.Transparency = 0.5 end)
			b.MouseButton1Click:Connect(onClick)
			return b
		end

		local FILTER_LABELS = {
			near  = "Meu boneco + perto",
			char  = "So no meu boneco",
			loose = "Meu boneco + sem dono",
			all   = "Todos os players",
		}
		local FILTER_CYCLE = { "near", "char", "loose", "all" }

		section("GERAL")
		makeToggle("Efeito ativo", cfg.enabled, function(v) setEnabled(v) end)
		makeToggle("Animacao / pulso", cfg.animate, function(v) cfg.animate = v end)
		makeToggle("Pecas neon do mapa", cfg.recolorParts, function(v)
			cfg.recolorParts = v
			resetAll()
		end)
		makeToggle("Preservar degrade", cfg.sequenceMode == "tint", function(v)
			cfg.sequenceMode = v and "tint" or "flat"
		end)

		local filterBtn
		filterBtn = makeButton("Filtro: " .. FILTER_LABELS[cfg.filterMode], function()
			local idx = table.find(FILTER_CYCLE, cfg.filterMode) or 1
			cfg.filterMode = FILTER_CYCLE[(idx % #FILTER_CYCLE) + 1]
			filterBtn.Text = "Filtro: " .. FILTER_LABELS[cfg.filterMode]
			resetAll()
			notify("Filtro: " .. FILTER_LABELS[cfg.filterMode])
		end)

		makeSlider("Raio (studs)", 5, 80, cfg.nearRadius, 0, function(v)
			cfg.nearRadius = v
		end)

		section("AJUSTES")
		makeSlider("Variacao de cor", 0, 0.25, cfg.hueJitter, 3, function(v) cfg.hueJitter = v end)
		makeSlider("Variacao de brilho", 0, 0.6, cfg.valueJitter, 3, function(v) cfg.valueJitter = v end)
		makeSlider("Detalhe interno", 0, 1, cfg.microJitter, 2, function(v) cfg.microJitter = v end)
		makeSlider("Brilho neon", 0, 1, cfg.lightEmission, 2, function(v) cfg.lightEmission = v end)
		makeSlider("Velocidade do pulso", 0, 2, cfg.animateSpeed, 2, function(v) cfg.animateSpeed = v end)

		section("COR PERSONALIZADA")
		local base = previewColor()
		local r, g, b = base.R * 255, base.G * 255, base.B * 255
		local function pushRGB()
			setCustomColor(r / 255, g / 255, b / 255, true)
		end
		makeSlider("R", 0, 255, r, 0, function(v) r = v; pushRGB() end)
		makeSlider("G", 0, 255, g, 0, function(v) g = v; pushRGB() end)
		makeSlider("B", 0, 255, b, 0, function(v) b = v; pushRGB() end)
		makeButton("Aplicar cor personalizada", function()
			setCustomColor(r / 255, g / 255, b / 255, false)
			notify(string.format("RGB %d, %d, %d", r, g, b))
		end)

		section("ACOES")
		makeButton("Restaurar cores originais", function()
			restoreAll()
			cfg.enabled = false
			notify("Cores originais restauradas")
		end)
		makeButton("Debug: listar efeitos (console)", function()
			debugDump()
			notify("Debug no console (F9)")
		end)
		makeButton("Fechar menu  (Right Shift)", function()
			gui.Enabled = false
		end)

		local statsLbl = inst("TextLabel", {
			Size = UDim2.new(1, -8, 0, 28), BackgroundTransparency = 1, Font = FONT_BODY,
			Text = "", TextColor3 = theme.sub, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = nextOrder(), Parent = right,
		})
		task.spawn(function()
			while running and statsLbl.Parent do
				task.wait(1)
				statsLbl.Text = string.format(
					"meu %d | mundo %d | perto %d | bloqueado %d\noutros players: %d",
					stats.mine, stats.world, stats.near, stats.blocked, stats.other)
			end
		end)

		refreshAccentRef = function()
			refreshAccent()
			local c = previewColor()
			brandGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, c),
			})
			local pb = palButtons[cfg.palette]
			if pb then
				if activePalBtn and activePalBtn ~= pb.btn then
					local s = activePalBtn:FindFirstChildOfClass("UIStroke")
					if s then s.Color = theme.track; s.Transparency = 0.5 end
				end
				activePalBtn = pb.btn
				pb.stroke.Color = previewColor()
				pb.stroke.Transparency = 0
			elseif activePalBtn then
				local s = activePalBtn:FindFirstChildOfClass("UIStroke")
				if s then s.Color = theme.track; s.Transparency = 0.5 end
				activePalBtn = nil
			end
		end

		return gui
	end

	--=================================================================
	-- BOOT
	--=================================================================
	local container = LP:WaitForChild("PlayerGui", 10)
	local okc, cg = pcall(function() return game:GetService("CoreGui") end)
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and typeof(h) == "Instance" then container = h end
	elseif okc and cg then
		container = cg
	end

	refreshWorld()
	log("mundo: raizes detectadas")
	for k in pairs(worldRoots) do log("   raiz ->", k:GetFullName()) end

	log("escaneando workspace...")
	scanRoot(workspace)
	log("dyn:", #list, "static:", #staticList,
		"| meu:", stats.mine, "outro:", stats.other, "mundo:", stats.world,
		"perto:", stats.near, "bloqueado:", stats.blocked)

	workspace.DescendantAdded:Connect(function(obj)
		task.defer(function()
			local st = safeRegister(obj)
			if st == "wait" and #pending < 5000 then
				pending[#pending + 1] = { obj = obj, tries = 0 }
			end
		end)
	end)

	-- rescan periodico
	task.spawn(function()
		while running do
			task.wait(cfg.rescanInterval)
			if cfg.enabled then
				rebuildList()
				scanRoot(workspace)
			end
		end
	end)

	-- re-detecta raizes de mundo (mapa streamado, ilhas novas)
	task.spawn(function()
		while running do
			task.wait(cfg.worldRefresh)
			refreshWorld()
		end
	end)

	-- loop de estaticos
	task.spawn(function()
		local c = 0
		while running do
			task.wait(cfg.staticInterval)
			local n = #staticList
			if n > 0 and cfg.enabled then
				local batch = math.min(600, n)
				for _ = 1, batch do
					c = c % n + 1
					local rec = staticList[c]
					if rec then pcall(applyRecord, rec) end
				end
			end
		end
	end)

	-- loop de render
	local lastTick = os.clock()
	local renderConn
	local cursor = 0
	local function startRenderLoop()
		if renderConn then pcall(function() renderConn:Disconnect() end) end
		renderConn = RunService.RenderStepped:Connect(function()
			lastTick = os.clock()
			if not cfg.enabled then return end
			local n = #list
			if n == 0 then return end
			local batch = math.clamp(math.ceil(n / 8), 60, 600)
			for _ = 1, batch do
				cursor = cursor + 1
				if cursor > n then cursor = 1 end
				local rec = list[cursor]
				if rec then pcall(applyRecord, rec) end
			end
		end)
	end
	startRenderLoop()

	-- watchdog
	task.spawn(function()
		while running do
			task.wait(4)
			if os.clock() - lastTick > 4 then
				log("watchdog: reiniciando loops")
				startRenderLoop()
				rebuildList()
				scanRoot(workspace)
				reapplyAll()
			end
		end
	end)

	if LP.Character then
		LP.CharacterAdded:Connect(function()
			task.wait(2)
			if not running then return end
			scanRoot(workspace)
			reapplyAll()
		end)
	end

	log("montando UI...")
	local gui
	local okUI, res = pcall(buildUI)
	if okUI then
		gui = res
		log("UI criada")
	else
		warn("[LUCXZZS] buildUI falhou: " .. tostring(res))
	end

	pcall(buildSplash, container)
	log("splash exibido")

	if gui then
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.KeyCode == Enum.KeyCode.RightShift then
				gui.Enabled = not gui.Enabled
			elseif input.KeyCode == Enum.KeyCode.V then
				local idx = table.find(paletteOrder, cfg.palette) or 0
				setPalette(paletteOrder[(idx % #paletteOrder) + 1])
			elseif input.KeyCode == Enum.KeyCode.B then
				setEnabled(not cfg.enabled)
			end
		end)
	end

	local ENV = (getgenv and getgenv()) or _G
	ENV.BFRecolor = {
		setPalette = setPalette,
		setColor   = function(r, g, b) setCustomColor(r / 255, g / 255, b / 255, false) end,
		toggle     = function() setEnabled(not cfg.enabled) end,
		restore    = function() setEnabled(false) end,
		show       = function() if gui then gui.Enabled = true end end,
		hide       = function() if gui then gui.Enabled = false end end,
		stats      = function() return #list, #staticList, stats end,
		setMode    = function(m)
			if not FILTER_LABELS_SET[m] then return end
			cfg.filterMode = m
			resetAll()
		end,
		setRadius  = function(r) cfg.nearRadius = math.clamp(r, 1, 200); resetAll() end,
		debugDump  = debugDump,
		config     = cfg,
		ui         = gui,
		destroy    = function()
			running = false
			restoreAll()
			if renderConn then pcall(function() renderConn:Disconnect() end) end
			if gui then pcall(function() gui:Destroy() end) end
		end,
	}
	local FILTER_LABELS_SET = { near = true, char = true, loose = true, all = true }

	log("TUDO PRONTO - RightShift abre/fecha")
end

--=====================================================================
-- EXECUCAO
--=====================================================================
local ok, err = xpcall(main, function(e)
	return tostring(e) .. "\n" .. debug.traceback("", 2)
end)

if not ok then
	warn("[LUCXZZS] ERRO FATAL:\n" .. tostring(err))
end
