if engine.ActiveGamemode() == "terrortown" then return end

AddCSLuaFile()

SWEP.PrintName			= "Samsung Galaxy S7 Edge"
SWEP.Category			= "Other"

SWEP.HoldType			= "normal"

SWEP.DrawCrosshair		= false

SWEP.Slot			= 4
SWEP.SlotPos			= 1

SWEP.Spawnable			= true
SWEP.DisableDuplicator		= true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.ViewModelFOV		= 10
SWEP.ViewModel			= Model("models/weapons/v_grenade.mdl")
SWEP.WorldModel			= ""

if SERVER then
	util.AddNetworkString("RemoveSamsungModel")
end
util.PrecacheModel("models/samsung_s7/samsung_s7.mdl")

local shouldplay = false
function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	shouldplay = true
	local dmg = math.Rand(150, 1337)

	timer.Simple(10, function()
		if SERVER and IsValid(self) and IsValid(self.Owner) and self.Owner:GetActiveWeapon() == self then
			util.BlastDamage(self, self.Owner, self:GetPos(), 150, dmg)

			local effect = EffectData()
			effect:SetStart(self:GetPos())
			effect:SetOrigin(self:GetPos())
			effect:SetScale(150)
			effect:SetRadius(150)
			effect:SetMagnitude(dmg)
			util.Effect("Explosion", effect, true, true)
			util.Effect("HelicopterMegaBomb", effect, true, true)

			self:Remove()
		end
		shouldplay = false
	end)
end

SWEP.SecondaryAttack = function() end

function SWEP:CanPrimaryAttack()
	return not shouldplay
end

function SWEP:Reload()
	return false
end

hook.Add("UpdateAnimation", "weapon_s7", function(ply, vel, maxseqgroundspeed)
	if shouldplay then
		ply:DoAnimationEvent(ACT_GMOD_IN_CHAT)
	end
end)

local dumb = false
function SWEP:Think()
	if IsValid(self.Owner) and self.Owner:GetActiveWeapon() == self and not dumb then
		self:SetHoldType("normal")
		dumb = true
	end
end

local function RemoveModel(ent)
	if CLIENT then
		if IsValid(LocalPlayer()) then
			local vm = LocalPlayer():GetViewModel()
			if IsValid(vm) and vm.GetBoneCount and vm:GetBoneCount() and vm:GetBoneCount() > 0 then
				local i = 0
				while i <= vm:GetBoneCount() do
					vm:ManipulateBoneScale(i, Vector(1, 1, 1))
					i = i + 1
				end
			end
		end
	else
		local worldmodel = ents.FindInSphere(ent.Owner:GetPos(), 0.6)
		for k, v in pairs(worldmodel) do 
			if v:GetClass() == "samsung_galaxy_s7_wmodel" and v:GetOwner() == ent.Owner then
				v:Remove()
			end
		end
	end

	if ent.WModel and IsValid(ent.WModel) then
		ent.WModel:Remove()
	end

	if ent.VModel and IsValid(ent.VModel) then
		ent.VModel:Remove()
	end
end

function SWEP:Deploy()
	if SERVER and IsValid(self.Owner) then
		local ent = ents.Create("samsung_galaxy_s7_wmodel")
		ent:SetOwner(self.Owner) 
		ent:SetParent(self.Owner)
		ent:SetPos(self.Owner:GetPos())
		ent:SetColor(self.Owner:GetColor())
		ent:SetMaterial(self.Owner:GetMaterial())
		ent:Spawn()

		self.Owner:DrawWorldModel(false)
	end

	return true
end

function SWEP:Holster()
	RemoveModel(self)
	return true
end

function SWEP:OnDrop()
	net.Start("RemoveSamsungModel")
	net.WriteBool(true)
	net.WriteEntity(self)
	net.Broadcast()
end

function SWEP:Equip()
	RemoveModel(self)
	net.Start("RemoveSamsungModel")
	net.WriteBool(false)
	net.WriteEntity(self)
	net.Broadcast()
end

function SWEP:OnRemove()
	RemoveModel(self)
	if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:Alive() then
		RunConsoleCommand("lastinv")
	end
end

if CLIENT then
	function SWEP:ViewModelDrawn()
		if IsValid(LocalPlayer()) then
			local vm = LocalPlayer():GetViewModel()
			if IsValid(vm) then
				if !IsValid(self.VModel) and vm.GetBoneCount and vm:GetBoneCount() then
					self.VModel = ents.CreateClientProp("models/samsung_s7/samsung_s7.mdl")
					local i = 0
					while i <= vm:GetBoneCount() do
						vm:ManipulateBoneScale(i, Vector(0.005, 0.005, 0.005))
						i = i + 1
					end
				elseif IsValid(self.VModel) then
					local vm = self.Owner:GetViewModel()
					local bp, ba = vm:GetBonePosition(vm:LookupBone("ValveBiped.Bip01_R_Hand"))
					bp = bp - ba:Forward() * 11 - ba:Up() * 8 - ba:Right() * 3
					self.VModel:SetPos(bp)
					ba:RotateAroundAxis(ba:Right(), -60)
					ba:RotateAroundAxis(ba:Forward(), 180)
					self.VModel:SetAngles(ba)
					self.VModel:SetParent(vm)
				end
			end
		end
	end

	hook.Add("Think", "EnforceViewModelSize", function()
		if IsValid(LocalPlayer()) then
			local vm = LocalPlayer():GetViewModel()
			if IsValid(vm) and vm.GetBoneCount and vm:GetBoneCount() and vm:GetBoneCount() > 0 and vm:GetModel() != "models/weapons/v_grenade.mdl" and vm:GetManipulateBoneScale(1) == Vector(0.005, 0.005, 0.005) then
				local i = 0
				while i < vm:GetBoneCount() do
					vm:ManipulateBoneScale(i, Vector(1, 1, 1))
					i = i + 1
				end
			end
		end
	end)

	net.Receive("RemoveSamsungModel", function()
		local drop = net.ReadBool()
		local wep = net.ReadEntity()
		RemoveModel(wep)
		if drop then
			wep.WModel = ents.CreateClientProp("models/samsung_s7/samsung_s7.mdl")
			if IsValid(wep.WModel) then
				wep.WModel:SetPos(wep:GetPos() - wep:GetUp() * 7)
				wep.WModel:SetParent(wep)
			end
		end
	end)
end

-- First of all, this code from "Hat maker" addon by CapsAdmin. So credits to him for this code. 
--_____________________________________________________________________
-- This is new "worldmodel" for Dead Ringer, because the model doesn't have custom holdtype animations and etc...
local ENT = {}

ENT.Type = "anim"
ENT.Model = Model("models/samsung_s7/samsung_s7.mdl")

function ENT:Initialize()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetModel(self.Model)
	self:DrawShadow(false)
end

function ENT:Think()
	local ply = self:GetOwner()
	self:SetColor(ply:GetColor())
	self:SetMaterial(ply:GetMaterial())
end

if CLIENT then
	function ENT:Draw()
		local p = self:GetOwner()
		local hand = p:LookupBone("ValveBiped.Bip01_L_Hand")

		if hand then
			local position, angles = p:GetBonePosition(hand)

			local x = angles:Up() * (-0.25)
			local y = angles:Right() * 1.40
			local z = angles:Forward() * 3.42

			local pitch = 89.20
			local yaw = 1.31
			local roll = 105.27

			angles:RotateAroundAxis(angles:Forward(), pitch)
			angles:RotateAroundAxis(angles:Right(), yaw)
			angles:RotateAroundAxis(angles:Up(), roll)

			self:SetPos(position + x + y + z)
			self:SetAngles(angles)
		end

		local eyepos = EyePos()
		local eyepos2 = LocalPlayer():EyePos()
		if eyepos:Distance(eyepos2) > 5 or LocalPlayer() != self:GetOwner() then
			self:DrawModel()
		end
	end
end

scripted_ents.Register(ENT, "samsung_galaxy_s7_wmodel")
