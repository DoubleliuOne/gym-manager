import { get, post } from '../utils/HttpUtil';
import { BookingRequest } from '../utils/HttpUtil';

interface ScheduleItem {
  id: number;
  courseId: number;
  coachId: number;
  classDate: string;
  startTime: string;
  endTime: string;
  actualCapacity: number;
  bookedCount: number;
  status: number;
}

interface CourseItem {
  id: number;
  name: string;
  description: string;
  maxCapacity: number;
  durationMinutes: number;
  status: number;
}

interface CoachItem {
  id: number;
  name: string;
  phone: string;
  specialty: string;
  status: number;
}

function getTimeLabel(time: string): string {
  return time.substring(0, 5);
}

@Entry
@Component
struct CourseList {
  @State scheduleList: ScheduleItem[] = [];
  @State courseMap: Record<number, string> = {};
  @State coachMap: Record<number, string> = {};
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.loading = true;
    try {
      const schedules = await get<ScheduleItem[]>('/schedules');
      const courses = await get<CourseItem[]>('/courses');
      const coaches = await get<CoachItem[]>('/coaches');

      this.scheduleList = schedules;

      let cm: Record<number, string> = {};
      for (let i = 0; i < courses.length; i++) {
        cm[courses[i].id] = courses[i].name;
      }
      this.courseMap = cm;

      let com: Record<number, string> = {};
      for (let i = 0; i < coaches.length; i++) {
        com[coaches[i].id] = coaches[i].name;
      }
      this.coachMap = com;
    } catch (err) {
      const msg = (err as Error).message || '加载课程列表失败';
      AlertDialog.show({
        title: '提示',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
    this.loading = false;
  }

  async handleBooking(scheduleId: number): Promise<void> {
    const memberData = AppStorage.get<object>('member');
    if (!memberData) {
      AlertDialog.show({
        title: '提示',
        message: '请先登录',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }
    let req: BookingRequest = {
      memberId: AppStorage.get<number>('memberId') ?? 0,
      scheduleId: scheduleId
    };
    try {
      await post<object>('/bookings', req);
      AlertDialog.show({
        title: '预约成功',
        message: '已成功预约该课程',
        confirm: {
          value: '确定',
          action: () => {
            this.loadData();
          }
        }
      });
    } catch (err) {
      const msg = (err as Error).message || '预约失败';
      AlertDialog.show({
        title: '预约失败',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    }
  }

  build() {
    Column() {
      Row() {
        Text('可预约课程')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [
          ['#1a1a2e', 0.0],
          ['#0f3460', 1.0]
        ]
      });

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(36).height(36)
            .color('#1a1a2e');
          Text('加载课程中...')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 12 });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else if (this.scheduleList.length === 0) {
        Column() {
          Column() {
            Text('📅')
              .fontSize(48);
          }
          .width(80).height(80)
          .backgroundColor('#f0f0f0')
          .borderRadius(40)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Text('暂无可预约课程')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        List({ space: 14 }) {
          ForEach(this.scheduleList, (item: ScheduleItem) => {
            ListItem() {
              Column() {
                Row() {
                  Text(this.courseMap[item.courseId] || ('课程#' + item.courseId))
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1a1a2e')
                    .layoutWeight(1);

                  Row() {
                    Text(getTimeLabel(item.startTime))
                      .fontSize(12)
                      .fontColor(Color.White)
                      .fontWeight(FontWeight.Medium);
                  }
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#e94560')
                  .borderRadius(6);
                }
                .width('100%');

                Row() {
                  Row() {
                    Column()
                      .width(6).height(6)
                      .backgroundColor('#1a1a2e')
                      .borderRadius(3);
                    Text('教练: ' + (this.coachMap[item.coachId] || ('教练#' + item.coachId)))
                      .fontSize(13).fontColor('#666666')
                      .margin({ left: 6 });
                  }
                  .margin({ right: 16 });

                  Text(item.classDate)
                    .fontSize(13).fontColor('#666666');
                }
                .width('100%')
                .margin({ top: 8 });

                Column()
                  .width('100%')
                  .height(1)
                  .backgroundColor('#f0f0f0')
                  .margin({ top: 12, bottom: 12 });

                Row() {
                  Column() {
                    Row() {
                      Text('已约 ' + item.bookedCount)
                        .fontSize(13)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(item.bookedCount >= item.actualCapacity ? '#e74c3c' : '#2ecc71');
                      Text(' / ' + item.actualCapacity + ' 人')
                        .fontSize(12).fontColor('#999999');
                    }
                    Row() {
                      Column()
                        .width((item.bookedCount / (item.actualCapacity || 1)) * 100 + '%')
                        .height(4)
                        .backgroundColor(item.bookedCount >= item.actualCapacity ? '#e74c3c' : '#2ecc71')
                        .borderRadius(2);
                    }
                    .width('100%')
                    .height(4)
                    .backgroundColor('#f0f0f0')
                    .borderRadius(2)
                    .margin({ top: 4 });
                  }
                  .layoutWeight(1)
                  .margin({ right: 12 });

                  Button() {
                    Text(item.bookedCount >= item.actualCapacity ? '已满' : '立即预约')
                      .fontSize(13)
                      .fontColor(Color.White)
                      .fontWeight(FontWeight.Medium);
                  }
                  .width(88).height(34)
                  .backgroundColor(item.bookedCount >= item.actualCapacity ? '#cccccc' : '#1a1a2e')
                  .borderRadius(8)
                  .enabled(item.bookedCount < item.actualCapacity)
                  .onClick(() => {
                    this.handleBooking(item.id);
                  });
                }
                .width('100%')
                .alignItems(VerticalAlign.Center);
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(14)
              .shadow({
                radius: 10,
                color: 'rgba(0,0,0,0.04)',
                offsetX: 0,
                offsetY: 4
              });
            }
          }, (item: ScheduleItem) => String(item.id));
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f6fa');
  }
}
