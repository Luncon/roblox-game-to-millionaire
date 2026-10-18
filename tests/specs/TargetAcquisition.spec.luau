return function()
 local Tactics=require(game.ServerScriptService.Game.CombatTactics)
 local cases=0
 local function actor(kind,x,owner)
  local rig={Name='SightFixture',GetAttribute=function()return kind end}
  return {rig=rig,kind=kind,position=Vector3.new(x,4,0),alive=true,claimed=true,ownerId=owner,neutral=owner==nil}
 end
 for _,entry in {{'warrior',50,52.5},{'ranged',85,90}}do
  local kind,extended,boundary=entry[1],entry[2],entry[3]
  for _,neutral in {false,true}do
   local source=actor(kind,0,if neutral then nil else 1)
   local enemy=actor('warrior',extended,2)
   assert(Tactics.chooseTarget(source,{source,enemy},nil,'advance')==enemy,'Troop ignored a hostile in extended sight')
   enemy.position=Vector3.new(boundary,4,0)
   assert(Tactics.chooseTarget(source,{source,enemy},nil,'advance')==enemy,'Sight boundary excluded')
   enemy.position=Vector3.new(boundary+.01,4,0)
   assert(Tactics.chooseTarget(source,{source,enemy},nil,'advance')==nil,'Fresh target beyond sight acquired')
  end
  cases+=1;print('PASS: '..kind..' owned and neutral sight extends by fifty percent with bounded acquisition')
 end
 for _,kind in {'warrior','ranged'}do
  local source=actor(kind,0,1);local enemy=actor('warrior',50,2)
  assert(Tactics.chooseTarget(source,{enemy},nil,'hold')==nil,'Extra sight increased Hold attack range')
  enemy.position=Vector3.new(if kind=='warrior' then 5 else 45,4,0)
  assert(Tactics.chooseTarget(source,{enemy},nil,'hold')==enemy)
 end
 cases+=1;print('PASS: increased sight preserves five-stud melee and forty-five-stud ranged Hold reach')
 local source=actor('warrior',0,1);local ally=actor('warrior',45,1);local dead=actor('warrior',46,2);dead.alive=false
 assert(Tactics.chooseTarget(source,{ally,dead},nil,'advance')==nil)
 cases+=1;print('PASS: extended sight still rejects allies and dead actors')
 return cases
end
