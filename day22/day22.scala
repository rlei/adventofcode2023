import scala.collection.mutable.HashMap

case class Coords3(x: Int, y: Int, z: Int)
case class Coords2(x: Int, y: Int)
case class Brick(from: Coords3, to: Coords3) {
  override def toString: String = s"Brick(${from.x},${from.y},${from.z} to ${to.x},${to.y},${to.z})"
}
case class ZAndBrickNo(topZ: Int, brickNo: Int)

def projectToXY(coords: Coords3): Coords2 = Coords2(coords.x, coords.y)

def parseCoord(s: String): Coords3 =
  val coords = s.split(',').map(_.toInt)
  Coords3(coords(0), coords(1), coords(2))

def iterXY(from: Coords2, to: Coords2): Seq[Coords2] =
  val xs = if from.x == to.x then List(from.x) else from.x to to.x by (to.x - from.x).sign
  val ys = if from.y == to.y then List(from.y) else from.y to to.y by (to.y - from.y).sign
  for
    x <- xs
    y <- ys
  yield Coords2(x, y)

def fallIn(xyMap: HashMap[Coords2, ZAndBrickNo],
    supportingMap: HashMap[Int, Set[Int]],
    supportedByMap: HashMap[Int, Set[Int]],
    brick: Brick, brickNo: Int): Unit =
  val fromXY = projectToXY(brick.from)
  val toXY = projectToXY(brick.to)
  val maxZ = iterXY(fromXY, toXY).map(xyMap.get(_).map(_.topZ).getOrElse(0)).max
  val supportingBrickNums = iterXY(fromXY, toXY)
    .map(xyMap.get(_))
    .filter(_.map(_.topZ == maxZ).getOrElse(false))
    .map(_.get.brickNo)
    .toSet
  supportingBrickNums.foreach(num =>
    val supporting = supportingMap.getOrElse(num, Set())
    supportingMap.update(num, supporting + brickNo))
  supportedByMap.update(brickNo, supportingBrickNums)

  assert(maxZ + 1 <= brick.from.z)
  val topZ = brick.to.z - (brick.from.z - (maxZ + 1))
  iterXY(fromXY, toXY).foreach(xyMap.update(_, ZAndBrickNo(topZ, brickNo)))

// Note supportedByMap will be mutated.
def findWouldFall(supportingMap: HashMap[Int, Set[Int]], supportedByMap: HashMap[Int, Set[Int]], blockNo: Int): Set[Int] =
  val supporting = supportingMap.getOrElse(blockNo, Set())
  supporting.foreach(num => supportedByMap.update(num, supportedByMap(num) - blockNo))
  val wouldFallNow = supporting.filter(supportedByMap(_).isEmpty)
  wouldFallNow ++ wouldFallNow.map(findWouldFall(supportingMap, supportedByMap, _)).flatten

@main def day22(): Unit =
  val bricks = io.Source.stdin.getLines()
    .map { _.split('~').map(parseCoord) }
    .map { coords => Brick(coords(0), coords(1)) }
    .toArray
    .sortInPlaceBy(_.from.z)

  // (x,y) => highest occupied Z and its brick #
  val xyMap = HashMap.empty[Coords2, ZAndBrickNo]
  val supportingMap = HashMap.empty[Int, Set[Int]]
  val supportedByMap = HashMap.empty[Int, Set[Int]]

  bricks.zipWithIndex.foreach((brick, no) => fallIn(xyMap, supportingMap, supportedByMap, brick, no))
  /*
  supportingMap.foreach((supporting, supported) =>
    println(s"block ${supporting} is supporting ${supported}"))
  supportedByMap.foreach((supported, by) =>
    println(s"block ${supported} is supported by ${by}"))
  */

  val canRemove = (0 until bricks.length).filter(
    supportingMap.getOrElse(_, Set()).forall(supportedByMap.get(_).get.size > 1)).toSet
  println(s"${canRemove.size} can be safely removed.")

  val others = (0 until bricks.length).filter(!canRemove.contains(_))

  val totalWouldFall = others.map(findWouldFall(supportingMap, supportedByMap.clone(), _)).map(_.size).sum
  println(s"${totalWouldFall} would fall in total.")
