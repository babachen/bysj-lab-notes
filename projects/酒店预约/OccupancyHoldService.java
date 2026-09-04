// 示意草稿，非可运行工程。锁与事务隔离级别自行定。
@Service
public class OccupancyHoldService {
  @Transactional
  public long hold(long guestId, long roomTypeId,
                   LocalDate in, LocalDate out, Instant now) {
    List<LocalDate> nights = in.datesUntil(out).toList();
    if (nights.isEmpty()) throw new IllegalArgumentException("empty stay");
    List<OccupancyDay> rows = occupancyRepo.lockDays(roomTypeId, nights);
    if (rows.size() != nights.size()) throw new IllegalStateException("calendar hole");
    for (OccupancyDay r : rows) {
      if (r.getLeftover() < 1) throw new IllegalStateException("sold out");
      r.setLeftover(r.getLeftover() - 1);
      r.setVersion(r.getVersion() + 1);
    }
    occupancyRepo.saveAll(rows);
    Reservation res = new Reservation();
    res.setGuestId(guestId);
    res.setRoomTypeId(roomTypeId);
    res.setCheckIn(in);
    res.setCheckOut(out);
    res.setStatus("HOLD");
    res.setHoldUntil(now.plusSeconds(15 * 60));
    return reservationRepo.save(res).getId();
  }
}
