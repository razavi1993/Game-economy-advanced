### A Pluto.jl notebook ###
# v0.19.38

using Markdown
using InteractiveUtils

# ╔═╡ 1381f2a5-060b-43a7-8e12-6755da9df3ca
using StatsBase

# ╔═╡ aec11380-484f-11ef-37e9-795ccb465251
abstract type Player end

# ╔═╡ 0792cb26-01f2-4dc6-a10b-b3acc60c3330
abstract type Policy end

# ╔═╡ 6b31649b-442d-40e6-b391-17dfa1a3984d
const MAX_HEALTH = 100

# ╔═╡ f17199da-9d50-41ee-b8d0-72d5ca4d49a9
abstract type Selling end

# ╔═╡ 5e5321ac-7a68-4b3a-bddb-5a744c61090c
mutable struct AttackingPolicy <: Policy
	attacking_prob::Float64
	fleeing_prob::Float64
end

# ╔═╡ 99e9a41c-169d-44bb-9bdc-925213b3da46
mutable struct PricePolicy <: Policy
	min_coeff::Int
	max_coeff::Int
end

# ╔═╡ 6614ef42-af85-44a8-9db0-0bb4c7d3244a
mutable struct AdventurerSelling <: Selling
	loot_package::Int
	loot_price::Int
end

# ╔═╡ ad749bf4-e4e5-41f5-b000-faa3c0208943
abstract type Weapon end

# ╔═╡ d0c475e7-e3e8-4111-b539-15d47f51edb4
mutable struct BasicWeapon <: Weapon
	attack::Int
	loot_required::Int
end

# ╔═╡ ce06df47-c25c-4aad-8c9f-abe85a33ba96
mutable struct WarriorWeapon <: Weapon
	attack::Int
	loot_required::Int
end

# ╔═╡ 084c2c24-cc2d-4654-a103-e00cb86db839
mutable struct LegendaryWeapon <: Weapon
	attack::Int
	loot_required::Int
end

# ╔═╡ 7fbd8b77-91aa-441d-897f-585929ea8671
mutable struct UltimateWeapon <: Weapon
	attack::Int
	loot_required::Int
end

# ╔═╡ 45bbcd9c-c1ab-4b1b-bbb3-85bc31cdf210
const BASIC_WEAPON = BasicWeapon(5, 0)

# ╔═╡ e3a0cd67-45e4-453f-9532-1ab7ed9914ea
const WEAPONS = [WarriorWeapon(10, 500), LegendaryWeapon(15, 2500), 
	             UltimateWeapon(20, 10000)]

# ╔═╡ ec2ecd45-2132-4b94-87ea-4d710dacdf22
mutable struct Craftsman <: Player
	loot::Int
	gold::Int
	crafted_weapon::Union{Nothing, Weapon}
	price_policy::PricePolicy
	weapon_level::Int
	weapon_price::Int
end

# ╔═╡ 4520690f-45b1-4e52-9c88-3ef6dfd69dee
mutable struct Adventurer <: Player
	loot::Int
	gold::Int
	health::Int
	heal::Int
	attacking_policy::AttackingPolicy
	selling::AdventurerSelling
	weapon_level::Int
	weapon::Weapon
end

# ╔═╡ 8c4d3cad-1535-437d-a1aa-c1a9a79b08fa
mutable struct Enemy
	health::Int
	attack::Int
	loot::Int
	gold::Int
end

# ╔═╡ bf4d2068-9033-4748-8fdc-18f35be34cff
function spawn_enemy(index)
	if index == 1
	    return Enemy(50, 5, 10, 1)
	elseif index == 2
		return Enemy(50, 5, 5, 1)
	elseif index == 3
		return Enemy(50, 5, 5, 2)
	else
		return Enemy(50, 5, 5, 4)
	end
end

# ╔═╡ 04ed226a-460d-432a-9850-c55bce1887cf
function set_price(craftsman::Craftsman)
	return rand(craftsman.price_policy.min_coeff*craftsman.weapon_level^2: 
	     craftsman.price_policy.max_coeff*craftsman.weapon_level^2)
end

# ╔═╡ 6e505e91-fbb2-4853-83b7-7c95757453ad
mutable struct Time
	length::Int
	step::Int
end

# ╔═╡ 08c457ff-d795-4d2d-b2a4-830492e22108
function craft_weapon!(craftsman::Craftsman)
	if craftsman.crafted_weapon != nothing 
		return nothing
	end
	if craftsman.weapon_level < 3 && craftsman.loot >= 		 
			WEAPONS[craftsman.weapon_level+1].loot_required
		craftsman.loot -= WEAPONS[craftsman.weapon_level+1].loot_required
		craftsman.crafted_weapon = WEAPONS[craftsman.weapon_level+1]
		craftsman.weapon_level += 1
		craftsman.weapon_price = set_price(craftsman)
	end
	return nothing
end

# ╔═╡ 3606639b-8a34-49b1-b00b-c654d584f69f
function buy_weapon!(adventurer::Adventurer, craftsmen::Vector{Craftsman})
	craftsmen_weapons = [craftsman.crafted_weapon for craftsman in craftsmen]
	if adventurer.weapon_level < 3 
		suitable_craftsmen = craftsmen[findall(craftsmen_weapons .== 
					     fill(WEAPONS[adventurer.weapon_level+1], length(craftsmen)))]
		if length(suitable_craftsmen) == 0 return nothing end
		required_weapon_prices = [suitable_craftsman.weapon_price for  
		                 suitable_craftsman in suitable_craftsmen]
		selected_craftsman = suitable_craftsmen[rand(findall(required_weapon_prices 
		                 .== minimum(required_weapon_prices)))]
		if adventurer.gold >= selected_craftsman.weapon_price
			adventurer.weapon = WEAPONS[adventurer.weapon_level+1]
			adventurer.gold -= selected_craftsman.weapon_price
			selected_craftsman.gold += selected_craftsman.weapon_price
			selected_craftsman.weapon_price = 0
			selected_craftsman.crafted_weapon = nothing
			adventurer.weapon_level += 1
		end
	end
	return nothing
end

# ╔═╡ f524d02a-0367-4b2e-bb7a-5702a3a83e79
function defeat_enemy!(player::Adventurer, enemy_index::Int, time::Time)
	enemy = spawn_enemy(enemy_index)
	while time.step < time.length
		if player.health > 0
			if enemy.health == 0
				player.loot += enemy.loot
				player.gold += enemy.gold
				player.health = MAX_HEALTH
				return 1
			else
				prob = rand()
				if rand() < player.attacking_policy.attacking_prob
					player.health -= min(player.health, enemy.attack)
					enemy.health -= min(player.weapon.attack, enemy.health)
				else
					if player.health < MAX_HEALTH
						player.health += min.(player.heal, MAX_HEALTH - player.health)
					end
				end
			end
		else
			player.health = MAX_HEALTH
			return 0
		end
		time.step += 1
	end
	player.health = MAX_HEALTH
	return 0
end

# ╔═╡ 775c0506-3bf4-4981-ac1a-c44b28be7141
begin
	mutable struct Line
		m::Float64
		b::Float64
	end
	(line::Line)(x) = line.m*x + line.b
end

# ╔═╡ 5749c4c9-a172-4b23-92de-1ca32453654b
construct_line(x1::Float64, x2::Float64, y1::Float64, y2::Float64) = 
				Line((y2 - y1)/(x2 - x1), (y1*x2 - y2*x1)/(x2 - x1))

# ╔═╡ 708a2fe9-3bd5-467a-a968-20186f30deff
construct_line(x1::Int, x2::Int, y1::Int, y2::Int) = 
				Line((y2 - y1)/(x2 - x1), (y1*x2 - y2*x1)/(x2 - x1))

# ╔═╡ 41f2d018-1178-4f94-8e06-e295f911240d
find_intersection(line1::Line, line2::Line) = [(line2.b-line1.b)/(line1.m-line2.m);        			 (line1.m*line2.b-line2.m*line1.b)/(line1.m-line2.m)]

# ╔═╡ 67559783-7f2f-40d1-8637-52b295c431a3
function sell_loot!(craftsman::Craftsman, adventurers::Vector{Adventurer})
	loot_packages = [adventurer.selling.loot_package for adventurer in adventurers]
	loot_prices = [adventurer.selling.loot_price for adventurer in adventurers]
	suitable_adventurers_indices = findall([adventurer.loot for adventurer in 
				   adventurers] .>= loot_packages)
	suitable_adventurers = adventurers[suitable_adventurers_indices]
	if length(suitable_adventurers) == 0 return nothing end
	loot_unit_price = loot_prices[suitable_adventurers_indices] ./ 
	               loot_packages[suitable_adventurers_indices]
	selected_adventurer = suitable_adventurers[rand(findall(loot_unit_price .== 	
				   minimum(loot_unit_price)))]
	while (craftsman.gold >= selected_adventurer.selling.loot_price) &&
				   (selected_adventurer.loot >=  
				   selected_adventurer.selling.loot_package)
		craftsman.gold -= selected_adventurer.selling.loot_price
		selected_adventurer.gold += selected_adventurer.selling.loot_price
		craftsman.loot += selected_adventurer.selling.loot_package
		selected_adventurer.loot -= selected_adventurer.selling.loot_package
	end
	return nothing
end

# ╔═╡ 425cc3c4-00ca-401c-9f04-3c62742aac0f
function play!(adventurers::Vector{Adventurer}, craftsmen::Vector{Craftsman},  
              enemy_index::Int, num_customers::Int, time_length::Int)
	times = [Time(time_length, 0) for i in range(1,length(adventurers))]
	enemies_killed = zeros(Int, length(adventurers))
	for i in range(1,length(adventurers))
		adventurer = adventurers[i]
		craftsman = craftsmen[i]
		while times[i].step < times[i].length
			enemies_killed[i] += defeat_enemy!(adventurer, enemy_index, times[i])
			customer_adventurers = sample(adventurers, num_customers, replace=false)
			sell_loot!(craftsman, customer_adventurers)
			craft_weapon!(craftsman)
			customer_craftsmen = sample(craftsmen, num_customers, replace=false)
			buy_weapon!(adventurer, customer_craftsmen)
		end
	end
	return enemies_killed
end

# ╔═╡ bd3fbb5d-5cf9-4d72-93ee-059ada9f19cc
begin
	loot_gold_prices = rand(1:3, 40)
	loot_values = 5*loot_gold_prices .+ rand(1:3, 40)
	attacking_probs = 0.3 .+ rand(0.0:0.01:0.4, 40)
	adventurers = [Adventurer(0, 0, 100, 5, AttackingPolicy(attacking_probs[i],  
		           1 - attacking_probs[i]),
				   AdventurerSelling(loot_values[i], loot_gold_prices[i]), 			  
				   0, BASIC_WEAPON) for i in range(1,40)]
end

# ╔═╡ c7436897-c6f1-4b83-8b26-8607cc789111
begin
	adventurers1 = adventurers[1:10]
	adventurers2 = adventurers[11:20]
	adventurers3 = adventurers[21:30]
	adventurers4 = adventurers[31:40]
end

# ╔═╡ 4c2d22c4-3161-4d99-ab76-f52621bfc251
begin
	craftsmen = [Craftsman(0, 1000, nothing, PricePolicy(rand(100:125), 
		         rand(250:300)), 0, 0) for i in range(1,40)]
end

# ╔═╡ eb8056bd-6aab-4e26-8c02-9ec3f5b55b24
begin
	craftsmen1 = craftsmen[1:10]
	craftsmen2 = craftsmen[11:20]
	craftsmen3 = craftsmen[21:30]
	craftsmen4 = craftsmen[31:40]
end

# ╔═╡ 99abcb33-a93a-406e-a44f-96e6ef17f98c
begin
	play!(adventurers1, craftsmen1, 1, 10, 10000)
	play!(adventurers2, craftsmen2, 2, 10, 10000)
	play!(adventurers3, craftsmen3, 3, 10, 10000)
	play!(adventurers4, craftsmen4, 4, 10, 10000)
end

# ╔═╡ f4c8938c-3f41-4142-bffe-3f57b12fedab
adventurers1

# ╔═╡ 7f251c43-c429-4274-9b90-eea3d34f6335
craftsmen1

# ╔═╡ 8107913f-e6ae-474b-97ef-d7e3718a5d53
adventurers2

# ╔═╡ 65098b82-40dd-41d0-b329-060ca2e59f1b
craftsmen2

# ╔═╡ e17b5bf9-4a2c-4d82-ae4a-e65039b437ca
adventurers3

# ╔═╡ 0b004328-64bd-4591-8bb8-8a7f254ca081
craftsmen3

# ╔═╡ c40b7cc5-3df5-4ccb-8943-417e17fa4d28
adventurers4

# ╔═╡ db43ed45-8bc3-4430-b0bc-9839d1190bd7
craftsmen4

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
StatsBase = "~0.34.3"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0"
manifest_format = "2.0"
project_hash = "476687e95d7dd2309be4c25d675735a3a2e77282"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "b1c55339b7c6c350ee89f2c1604299660525b248"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.15.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "a2d09619db4e765091ee5c6ffe8872849de0feea"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.28"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+2"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "5cf7606d6cef84b543b483848d4ae08ad9832b21"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.3"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"
"""

# ╔═╡ Cell order:
# ╠═1381f2a5-060b-43a7-8e12-6755da9df3ca
# ╠═aec11380-484f-11ef-37e9-795ccb465251
# ╠═0792cb26-01f2-4dc6-a10b-b3acc60c3330
# ╠═6b31649b-442d-40e6-b391-17dfa1a3984d
# ╠═f17199da-9d50-41ee-b8d0-72d5ca4d49a9
# ╠═5e5321ac-7a68-4b3a-bddb-5a744c61090c
# ╠═99e9a41c-169d-44bb-9bdc-925213b3da46
# ╠═6614ef42-af85-44a8-9db0-0bb4c7d3244a
# ╠═ad749bf4-e4e5-41f5-b000-faa3c0208943
# ╠═d0c475e7-e3e8-4111-b539-15d47f51edb4
# ╠═ce06df47-c25c-4aad-8c9f-abe85a33ba96
# ╠═084c2c24-cc2d-4654-a103-e00cb86db839
# ╠═7fbd8b77-91aa-441d-897f-585929ea8671
# ╠═45bbcd9c-c1ab-4b1b-bbb3-85bc31cdf210
# ╠═e3a0cd67-45e4-453f-9532-1ab7ed9914ea
# ╠═ec2ecd45-2132-4b94-87ea-4d710dacdf22
# ╠═4520690f-45b1-4e52-9c88-3ef6dfd69dee
# ╠═8c4d3cad-1535-437d-a1aa-c1a9a79b08fa
# ╠═bf4d2068-9033-4748-8fdc-18f35be34cff
# ╠═04ed226a-460d-432a-9850-c55bce1887cf
# ╠═6e505e91-fbb2-4853-83b7-7c95757453ad
# ╠═08c457ff-d795-4d2d-b2a4-830492e22108
# ╠═3606639b-8a34-49b1-b00b-c654d584f69f
# ╠═f524d02a-0367-4b2e-bb7a-5702a3a83e79
# ╠═775c0506-3bf4-4981-ac1a-c44b28be7141
# ╠═5749c4c9-a172-4b23-92de-1ca32453654b
# ╠═708a2fe9-3bd5-467a-a968-20186f30deff
# ╠═41f2d018-1178-4f94-8e06-e295f911240d
# ╠═67559783-7f2f-40d1-8637-52b295c431a3
# ╠═425cc3c4-00ca-401c-9f04-3c62742aac0f
# ╠═bd3fbb5d-5cf9-4d72-93ee-059ada9f19cc
# ╠═c7436897-c6f1-4b83-8b26-8607cc789111
# ╠═4c2d22c4-3161-4d99-ab76-f52621bfc251
# ╠═eb8056bd-6aab-4e26-8c02-9ec3f5b55b24
# ╠═99abcb33-a93a-406e-a44f-96e6ef17f98c
# ╠═f4c8938c-3f41-4142-bffe-3f57b12fedab
# ╠═7f251c43-c429-4274-9b90-eea3d34f6335
# ╠═8107913f-e6ae-474b-97ef-d7e3718a5d53
# ╠═65098b82-40dd-41d0-b329-060ca2e59f1b
# ╠═e17b5bf9-4a2c-4d82-ae4a-e65039b437ca
# ╠═0b004328-64bd-4591-8bb8-8a7f254ca081
# ╠═c40b7cc5-3df5-4ccb-8943-417e17fa4d28
# ╠═db43ed45-8bc3-4430-b0bc-9839d1190bd7
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
