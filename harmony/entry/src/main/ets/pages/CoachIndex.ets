import router from '@ohos.router';
import { get, post } from '../utils/HttpUtil';

interface CoachInfo {
  id: number;
  name: string;
  phone: string;
  specialty: string;
}

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
}

interface StudentItem {
  id: number;
  name: string;
  phone: string;
  gender: number;
}

@Entry
@Component
struct CoachIndex {
  @State coachId: number = 0;
  @State coachName: string = '';
  @State coachPhone: string = '';
  @State coachSpecialty: string = '';
  @State scheduleList: ScheduleItem[] = [];
  @State studentList: StudentItem[] = [];
  @State courseMap: Record<number, string> = {};
  @State loadingSchedules: boolean = true;
  @State loadingStudents: boolean = true;
  @State currentTab: number = 0;

  aboutToAppear(): void {
    this.checkAuth();
  }

  checkAuth(): void {
    const token = AppStorage.get<string>('token');
    if (!token) { try { router.replaceUrl({ url: 'pages/Login' }); } catch (_) {} return; }
    const memberData = AppStorage.get<object>('member');
    const coachIdFromStorage = AppStorage.get<number>('coachId');
    if (memberData) {
      const c = memberData as Record<string, Object>;
      this.coachId = (coachIdFromStorage != null ? coachIdFromStorage : 0);
      this.coachName = (c["name"] as string) ?? '';
      this.coachPhone = (c["phone"] as string) ?? '';
      this.coachSpecialty = (c["specialty"] as string) ?? '';
      this.loadSchedules();
      this.loadStudents();
    } else {
      this.loadingSchedules = false;
      this.loadingStudents = false;
    }
  }

  async loadSchedules(): Promise<void> {
    this.loadingSchedules = true;
    try {
      const schedules = await get<ScheduleItem[]>('/schedules?coachId=' + this.coachId);
      const courses = await get<CourseItem[]>('/courses');
      this.scheduleList = schedules;
      let cm: Record<number, string> = {};
      for (let i = 0; i < courses.length; i++) { cm[courses[i].id] = courses[i].name; }
      this.courseMap = cm;
    } catch (_) {}
    this.loadingSchedules = false;
  }

  async loadStudents(): Promise<void> {
    this.loadingStudents = true;
    try {
      const students = await get<StudentItem[]>('/coaches/' + this.coachId + '/students');
      this.studentList = students;
    } catch (_) {}
    this.loadingStudents = false;
  }

  handleLogout(): void {
    AppStorage.delete('token');
    AppStorage.delete('member');
    try { router.replaceUrl({ url: 'pages/Login' }); } catch (_) {}
  }

  build() {
    Column() {
      Row() {
        Text('教练端').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#ffffff');
      }.width('100%').height(56).padding({ left: 20, right: 20 })
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [['#1a1a2e', 0.0], ['#0f3460', 1.0]]
      });

      Tabs({ index: this.currentTab, barPosition: BarPosition.End }) {
        TabContent() { this.scheduleTab(); }
          .tabBar(this.tabBuilder('我的课程', 0))
        TabContent() { this.studentsTab(); }
          .tabBar(this.tabBuilder('我的学员', 1))
        TabContent() { this.profileTab(); }
          .tabBar(this.tabBuilder('个人', 2))
      }.width('100%').layoutWeight(1)
      .onChange((index: number) => { this.currentTab = index; });
    }.width('100%').height('100%').backgroundColor('#f5f6fa');
  }

  @Builder
  tabBuilder(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor(this.currentTab === index ? '#1a1a2e' : '#999999')
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal);
      Column()
        .width(16)
        .height(3)
        .backgroundColor(this.currentTab === index ? '#1a1a2e' : 'transparent')
        .borderRadius(2)
        .margin({ top: 4 });
    }
    .padding({ top: 8, bottom: 8 })
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  scheduleTab() {
    Column() {
      if (this.loadingSchedules) {
        Column() {
          LoadingProgress().width(36).height(36).color('#1a1a2e');
          Text('加载中...').fontSize(13).fontColor('#999999').margin({ top: 12 });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else if (this.scheduleList.length === 0) {
        Column() {
          Text('📅').fontSize(48);
          Text('暂无排课安排').fontSize(16).fontColor('#999999').margin({ top: 12 });
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
                  // 日期标签
                  Column() {
                    Text(item.classDate.substring(8, 10))
                      .fontSize(22)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1a1a2e');
                    Text(getMonthDay(item.classDate))
                      .fontSize(11)
                      .fontColor('#999999')
                      .margin({ top: 2 });
                  }
                  .width(50)
                  .alignItems(HorizontalAlign.Center);

                  Column() {
                    Text(this.courseMap[item.courseId] || ('课程#' + item.courseId))
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1a1a2e')
                      .width('100%');
                    Text(item.startTime.substring(0, 5) + ' - ' + item.endTime.substring(0, 5))
                      .fontSize(13)
                      .fontColor('#666666')
                      .width('100%')
                      .margin({ top: 4 });
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .margin({ left: 12 });

                  // 容量
                  Column() {
                    Text(item.bookedCount + '/' + item.actualCapacity)
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(item.bookedCount >= item.actualCapacity ? '#e74c3c' : '#2ecc71');
                    Text('已预约')
                      .fontSize(10)
                      .fontColor('#999999')
                      .margin({ top: 2 });
                  }
                  .alignItems(HorizontalAlign.Center);
                }
                .width('100%');
              }
              .width('100%').padding(16).backgroundColor(Color.White).borderRadius(14)
              .shadow({ radius: 6, color: 'rgba(0,0,0,0.03)', offsetX: 0, offsetY: 2 });
            }
          }, (item: ScheduleItem) => String(item.id));
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 16 });
      }
    }.width('100%').height('100%');
  }

  @Builder
  studentsTab() {
    Column() {
      if (this.loadingStudents) {
        Column() {
          LoadingProgress().width(36).height(36).color('#1a1a2e');
          Text('加载中...').fontSize(13).fontColor('#999999').margin({ top: 12 });
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else if (this.studentList.length === 0) {
        Column() {
          Text('👥').fontSize(48);
          Text('暂无私教学员').fontSize(16).fontColor('#999999').margin({ top: 12 });
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        List({ space: 12 }) {
          ForEach(this.studentList, (s: StudentItem) => {
            ListItem() {
              Row() {
                Column() {
                  Text(s.name.substring(0, 1))
                    .fontSize(18)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Bold);
                }
                .width(44).height(44)
                .backgroundColor('#1a1a2e')
                .borderRadius(22)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center);

                Column() {
                  Text(s.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#1a1a2e');
                  Text(s.phone).fontSize(13).fontColor('#999999').margin({ top: 2 });
                }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 });

                Text(s.gender === 1 ? '♂ 男' : (s.gender === 2 ? '♀ 女' : '-'))
                  .fontSize(13)
                  .fontColor(s.gender === 1 ? '#2ecc71' : '#e94560');
              }
              .width('100%').padding(16).backgroundColor(Color.White).borderRadius(14)
              .shadow({ radius: 6, color: 'rgba(0,0,0,0.03)', offsetX: 0, offsetY: 2 });
            }
          }, (s: StudentItem) => String(s.id));
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 16 });
      }
    }.width('100%').height('100%');
  }

  @Builder
  profileTab() {
    Column() {
      // 教练个人资料卡片
      Column() {
        Column() {
          Column()
            .width(72)
            .height(72)
            .backgroundColor('rgba(255,255,255,0.2)')
            .borderRadius(36);

          Text(this.coachName)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ top: 12 });

          Text(this.coachSpecialty)
            .fontSize(14)
            .fontColor('rgba(255,255,255,0.7)')
            .margin({ top: 4 });

          Text('手机号: ' + this.coachPhone)
            .fontSize(13)
            .fontColor('rgba(255,255,255,0.5)')
            .margin({ top: 4 });
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 32, bottom: 24 });
      }
      .width('100%')
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [['#1a1a2e', 0.0], ['#0f3460', 1.0]]
      })
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 16, bottomRight: 16 });

      Button() {
        Text('退出登录')
          .fontSize(16)
          .fontColor('#e74c3c')
          .fontWeight(FontWeight.Medium);
      }
      .width('100%')
      .height(50)
      .backgroundColor(Color.White)
      .borderRadius(14)
      .margin({ left: 16, right: 16, top: 24 })
      .shadow({
        radius: 6,
        color: 'rgba(0,0,0,0.03)',
        offsetX: 0,
        offsetY: 2
      })
      .onClick(() => { this.handleLogout(); });

      Text('v1.0.0')
        .fontSize(12)
        .fontColor('#cccccc')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 32 });
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start);
  }
}

function getMonthDay(date: string): string {
  const parts = date.split('-');
  if (parts.length >= 2) {
    return parts[1] + '月';
  }
  return '';
}
