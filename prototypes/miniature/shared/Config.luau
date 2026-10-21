--!strict
return table.freeze({
 scale=.25,groundY=.4,walkSpeed=3,workerSpeed=1.5,
 plotSize=Vector3.new(40,.4,32),
 buildings=table.freeze({
  house=table.freeze({name='Spartan House',description='Housing for the people who will work in your civilization. This preview demonstrates scale; population is not simulated yet.',position=Vector3.new(-9,.4,-6)}),
  farm=table.freeze({name='Grain Farm',description='Two miniature workers tend the grain. Production, collecting and selling will be added in the next playable slice.',position=Vector3.new(8,.4,-6)}),
  barracks=table.freeze({name='Spartan Barracks',description='Three spearmen and one archer patrol the yard. Your avatar commands the army; players do not fight.',position=Vector3.new(-9,.4,7)}),
 }),
 patrol=table.freeze({Vector3.new(2,.4,4),Vector3.new(13,.4,4),Vector3.new(13,.4,12),Vector3.new(2,.4,12)}),
})
