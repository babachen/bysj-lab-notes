// 示意草稿：赤道近似，半径与坐标必须写入订单行
static boolean inRadius(double uLat, double uLng, double sLat, double sLng, int radiusM) {
  double r = 6371000.0;
  double dLat = Math.toRadians(sLat - uLat);
  double dLng = Math.toRadians(sLng - uLng);
  double a = Math.sin(dLat/2)*Math.sin(dLat/2)
      + Math.cos(Math.toRadians(uLat))*Math.cos(Math.toRadians(sLat))
      * Math.sin(dLng/2)*Math.sin(dLng/2);
  double meters = 2 * r * Math.asin(Math.sqrt(a));
  return meters <= radiusM;
}
