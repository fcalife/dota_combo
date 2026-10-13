PrecacheManager = PrecacheManager or {}

local sounds = {
	"soundevents/custom_soundboard_soundevents.vsndevts",
}

function PrecacheManager:PrecacheWebInventory(context)
	if not ITEM_DEFINITIONS then print("[Precache Manager] no definitions on precache run!") return end
	for item_name, data in pairs(ITEM_DEFINITIONS or {}) do
		if data.particles then
			for _, particle_data in pairs(data.particles) do
				print("[Precache Manager] precaching particle", particle_data.path)
				PrecacheResource("particle", particle_data.path, context)
			end
		end
		if data.particle_variants then
			for _, particle_data in pairs(data.particle_variants) do
				print("[Precache Manager] precaching particle variant", particle_data.path)
				PrecacheResource("particle", particle_data.path, context)
			end
		end
		if data.blink_particles then
			if data.blink_particles.start_name then
				PrecacheResource("particle", data.blink_particles.start_name, context)
			end
			if data.blink_particles.end_name then
				PrecacheResource("particle", data.blink_particles.end_name, context)
			end
		end
	end
end


function PrecacheManager:Run(context)
	PrecacheManager:PrecacheWebInventory(context)

	for _, p in pairs(sounds) do
		PrecacheResource("soundfile", p, context)
	end
end

