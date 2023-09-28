![Yamms logo](https://raw.githubusercontent.com/Mattiny/yamms/main/icon.svg)
# YAMMS - Yet Another MultiMesh Scatter
## A plugin for Godot to place MultiMesh meshes into the game world.

Author: Mattiny
Youtube: https://youtu.be/783reAHkYFc

Note: This plugin is only compatible with Godot 4.0 and following Godot versions.
![Screenshot_01](https://user-images.githubusercontent.com/127634166/224740362-c7ddbf76-da05-48d6-a1a2-7aacbeb36a8a.png)
## Features

- Place MultiMeshInstances of different types into your scene.
- Configure the proportions of how many meshes of each type shall be placed into your scene.
- Set up an area via Path3D polygon in which the meshes shall placed.
- Set up exclusion areas via Path3D polygons (inside your area definition) to leave these areas empty.
- Configure the height of the generated meshes: "Flat", "Floating", "Dropped on floor", "Dropped on ceiling".
- Add additional scenes (e.g. collision objects) at the same position as the MultiMeshInstance3D instances.

## Installation
- Download from GitHub: https://github.com/Mattiny/yamms
- Download via Asset library in Godot and activate the plugin.
 
## Usage
### MultiScatter
The MultiScatter is the main node of the whole MultiMesh scatter set up.
- In your Scene: Add the node "MultiScatter"
- Whenever the MultiScatter node is selected: The Editor shows buttons to set up a polygon. Add at least 3 point which span an area which is large enough to hold the meshes. Best practice: Change to orthogonal top view of your scene (key "7").
![01-Initial-MultiScatter](https://github.com/Mattiny/yamms/assets/127634166/934aa284-2341-4b17-8b8b-2f2bbd2984e7)
- In Inspector set up properties:
	- **Amount**: the amount of meshes which are generated into the scene.
	- **Seed**: The random number generator seed. Using a seed makes the pattern of randomly generated meshes reproducible. Change the seed until you are satisfied with the result.
	- **Collision mask**: When using "Dropped on floor": set up which collision detection mask shall be used to identify the floor.
	- **Floating min max**: Set up the min- max- range of the mesh's height when floating.
 	- **Debug messages**: Write additional output messages when generating the MultiMeshInstance3D positions. (as the name says: for debug purposes, when something does not work as expected)

### MultiScatterItem
The MultiScatterItem keeps information about one type of meshes in the MultiMesh set up. It needs to be a child node underneath the MultiScatter node. There can be multiple MultiScatterItems in one MultiScatter.

- In your scene: Add the node "MultiScatterItem" as a child node to a MultiScatter node.
- Select the MultiScatterItem.
- Set up parameters:
	- **Proportion**: The amount proportion for this mesh. The exact amount depends on the "Amount" property of the parent MultiScatter and the proportion of sibling MultiScatterItems.
    	- **Placement mode**: Specifies how the meshes are placed into your scene.
		- **Flat**: all meshes are generated on a flat simple plane.
		- **Floating**: all meshes are generated floating in 3D space
		- **Dropped on floor**: all meshes are generated on the floor. This requires a sufficiently large object with collision shape underneath. Note: The whole polygon must be hovering ABOVE the ground.
   	  	- **Dropped on ceiling**: all meshes are generated on the ceiling. This requires a sufficiently large object with collision shape above. Note: The whole polygon must be hovering UNDERNEATH the collision object.
	- **Random Rotation**: if activated: The max angle of the random rotation of each mesh.
	- **Random Scale**: if activated: The max random scale of each mesh.
 	- **Additional Scene**: Places an additional scene (PackedScene) at the same position as the scattered item. Can be used e.g. to put collision objects at the same position. **Note** It is a real scene, not a primitive MultiScatterItem3D. So it uses more resources at runtime than MultiMeshInstances. It is not supposed to be used with too many instances.
  		- **Target Node**: References the node where the scenes are placed in the scene tree. **Note** Don't place any other relevant Nodes of your scene underneath the referenced node. Whenever the MultiMeshInstance3D positions are generated, the target node will be deleted (without question).
  		- **Additional scene**: Reference to a PackedScene which will be instantiated and placed at the same position as the MultiMeshInstance3D.
    	- **Excludes**: is an array of references to MultiScatterExclude instances. If left empty (default) all MultiScatterExclude areas underneath the MultiScatter element are considered when generating the MultiMeshInstance3D positions. But if at least one exclude-area refrence is put into the array of "excludes", then only the referenced exclude-areas are active for this MultiScatterItem.  


#### Set up a MultiMeshInstance3D (standard Godot behaviour)
- In the inspector: Paramter "MultiMesh": Create a new MultiMesh
- Click at the new MultiMesh: The MultiMesh parameters open and are editable
- set "Transform Format" to "3D"
- Drag & Drop a mesh from your file system into the inspector property "Mesh"
- If necessary: Drag & Drop a material for this mesh to inspector property "Geometry / Material override"
![Set up MultScatterItem](https://user-images.githubusercontent.com/127634166/224749498-f22a347a-2520-4899-a6f1-3f294d2dec3c.png)


### MultiScatterExclude
The MultiScatterExclude defines a sub area which is left empty without any mesh generated in it. It is expected to be 
a child node of MultiScatter. There can be more than one MultiScatterExclude in one MultiScatter.

As done for MultiScatter: set up points of the area polygon. It only makes sense to place the polygon inside (or at least overlap) the area of the MultiScatter.
- Do not place a MultiScatterExclude completely outside the MultiScatter area (Well, if you want to: do it. But it won't have any effect then.)
- Do not cover the whole MultiScatter area with MultiScatterExclude areas. This way no meshes will be generated because there is no room for the meshes.
- MultiScatterItems can refer to specific MultiScatterExclude instances. This can be set up in the MultiScatterItem. Then only the selected MultiScatterExclude instances apply to that MultiScatterItem.
![Excluded Area](https://user-images.githubusercontent.com/127634166/224751430-f9619a4e-5bd7-4df0-ba8f-5e94289a7a4f.png)
### Generate
Once the MultiScatter set up has been completed, select the MultiScatter node again. Right next to the buttons which let you draw the polygon there is a "Generate" button.
Hit the generate button and all meshes are generated and placed into your scene.

You still can edit your set up (move polygons, add/remove points to polygons, add MultiScatterItems, etc). But remember: to make these changes effective you need to hit the "Generate" button again.

![Generate](https://user-images.githubusercontent.com/127634166/224752651-d2a880b3-40af-48ea-ac7b-31c6bed45162.png)


### Placement Modes examples
![Drop on Floor](https://user-images.githubusercontent.com/127634166/224754906-d7a9f054-8350-4a57-ab93-ec5a2359a277.png)
![Flat](https://user-images.githubusercontent.com/127634166/224755082-7e8175ca-62d7-4bb9-b8b9-6dfef52efb96.png)
![Floating](https://user-images.githubusercontent.com/127634166/224755268-d2387e14-3666-44a3-a031-99751856045c.png)

