# Sortree

A tree-like data structure for performing complex, persistent sorting.

This data structure was originally intended for sorting rendering draw
calls in a relatively efficient way, and subsequently maintaining that sort
order with minimal overhead. It may have broader applications, but will for 
many use cases either be overkill or lack flexibility.

A sort tree will only sort objects that extend (not just implement) the
`SortTreeEntry` class. Additionally the values that you wish to split/group/sort
by must be wrapped in a `DecisionValue` (e.g. `StaticValue` or `MutableValue`).

## Example

```dart
import 'package:sortree/sortree.dart';

/// A draw call that renders a piece of geometry.
class ObjectDrawCall extends SortTreeEntry {
  /// The opacity of the object being rendered.
  final MutableValue<num> opacity;
  
  /// The 'material' used on the object being rendered.
  final StaticValue<Material> material;
  
  /// Distance between the object being rendered and the camera.
  final MutableValue<num> cameraDistance;
  
  ...
}
```

If we have a large number of such draw calls, we can use a sort tree to attempt to
arrange these in an order that results both in the objects being displayed correctly
and efficiently. Notably we may want to order such that:

- All opaque objects are rendered before objects that are (slightly) translucent.
  When translucency is achieved by color blending, this is necessary to ensure the
  objects display correctly.
- All translucent objects are rendered in order from furthest to closest to the camera
  (for the same reason as above).
- All opaque objects are grouped by the material they use. Changing to a different
  material typically involves making a lot of changes to the rendering pipeline which
  may be costly. Reducing the amount of changes may therefore increase performance.
- The material groups are ordered such that the group closest to the camera is rendered
  first and the group furthest from the camera is rendered last. This may allow us to
  take advantage of 'early Z optimization', where triangles that are occluded by objects
  closer to the camera can be discarded early, resulting in less strain on the GPU.
  
To achieve these things we would construct the following sort tree:

```dart
// First we split our draw call into 2 groups based on whether or not
// they are translucent using a SplitterNode.
final sorter = new SplitterNode<ObjectDrawCall, num>(
    on: (drawCall) => drawCall.opacity,
    test: (opacity) => opacity >= 1,
    
    // The opaque objects (objects that pass our test `opacity >= 1`) are 
    // passed on to a GroupingNode that groups by material.
    successBranch: new GroupingNode<ObjectDrawCall, Material>(
        by: (drawCall) => drawCall.material,
        
        // We collect each material group in a CollectorNode that will
        // sort by camera distance in ascending order, meaning that the
        // objects closest to the camera will be traversed first to 
        // potentially take advantage of early Z optimization.
        makeBranch: (material) => new CollectorNode<ObjectDrawCall>(
            sortBy: (drawCall) => drawCall.cameraDistance,
            branchOrder: Order.ascending,
            
            // We specify the sort code for the CollectorNode to be the
            // same as the sort code of its first child branch. This will
            // allow the parent GroupingNode order the material groups
            // based roughly on their proximity to the camera.
            sortCode: (node) => new BranchSortCodeFirst(node)
        ),
        // We set the branch order on the GroupingNode to ascending to
        // render the material groups closest to the camera first (early Z).
        branchOrder: Order.ascending,
        sortCode: (node) => StaticValue(0)
    ),
    
    // The translucent objects are passed straight onto a CollectorNode that
    // sorts them by camera distance in descending order so that the objects
    // furthest from the camera are traversed first. We don't group by material
    // here, because for translucent objects the distance ordering is not just
    // an optimization, it is required for correct display; grouping by material
    // first would not guarantee the correct order.
    failureBranch: new CollectorNode<ObjectDrawCall>(
        sortBy: (drawCall) => drawCall.cameraDistance,
        branchOrder: Order.descending,
        sortCode: (node) => StaticValue(1)
    ),
    
    // We gave our success branch a static sort code of 0 and our
    // failure branch a static sort code of 1. If we now declare
    // our branch order to be ascending, all opaque objects will
    // be traversed before the translucent objects.
    branchOrder: Order.ascending
);
```

The class documentation for `SplitterNode`, `GroupingNode` and `CollectorNode`
has more details on how they are used.

We would then pass our draw call to this sorter using the `process` method:

```dart
sorter.process(someDrawCall);
```

Now we can iterate over the draw calls in the sorter and they will be traversed
in the order we declared:

```dart
for (final drawCall in sorter) {
  drawCall.draw();
}
```

If we change a `MutableValue` on an `ObjectDrawCall` (e.g. `cameraDistance`) the
tree will adjust automatically and when the sorter is next traversed.

Note that this is merely one example of how draw calls might be ordered. The order
that yields maximum performance will depend on your application. For example, you may
also want to group by geometry (to take advantage of instancing optimizations), or
you may want to assign your opaque objects camera distance zones (e.g. zone 1 0-1 
meters, zone 2 1-10 meters, zone 3 10-... meters) rather than raw camera distances
to avoid some sorting overhead while still largely getting the same Early Z benefits.
