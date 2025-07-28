/**
 * 高级日期格式化工具
 * @param date Date对象、时间戳或可转换为Date的字符串
 * @param format 格式字符串，默认'YYYY-MM-DD HH:mm:ss'
 * @param options 额外选项
 * @returns 格式化后的日期字符串
 */
export function formatDateAdvanced(
  date: Date | number | string,
  format: string = 'YYYY-MM-DD HH:mm:ss',

): string {
  let d: Date;

  // 处理传入参数
  if (typeof date === 'number') {
    d = new Date(date);
  } else if (date instanceof Date) {
    d = date;
  } else if (typeof date === 'string') {
    d = new Date(date);
    if (isNaN(d.getTime())) {
      throw new Error('Invalid date string');
    }
  } else {
    throw new Error('Invalid date parameter');
  }

  // 补零函数
  const padZero = (num: number): string => num.toString().padStart(2, '0');

  // 提取日期各部分
  const year = d.getFullYear();
  const month = d.getMonth() + 1;
  const day = d.getDate();
  const hours = d.getHours();
  const minutes = d.getMinutes();
  const seconds = d.getSeconds();
  const dayOfWeek = d.getDay();

  // 星期名称（中英文）
  const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']


  // 替换格式标记
  let result = format
    .replace('YYYY', year.toString())
    .replace('YY', year.toString().slice(-2))
    .replace('MM', padZero(month))
    .replace('M', month.toString())
    .replace('DD', padZero(day))
    .replace('D', day.toString())
    .replace('HH', padZero(hours))
    .replace('H', hours.toString())
    .replace('mm', padZero(minutes))
    .replace('m', minutes.toString())
    .replace('ss', padZero(seconds))
    .replace('s', seconds.toString());


  result = result.replace('WW', weekdays[dayOfWeek]);


  return result;
}