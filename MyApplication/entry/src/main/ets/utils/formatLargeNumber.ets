export function formatLargeNumber(num: number): string {
  if (num === 0) {
    return '0';
  }

  const absNum = Math.abs(num);
  const sign = num < 0 ? '-' : '';

  if (absNum >= 1e12) {
    return sign + (absNum / 1e12).toFixed(2) + 'T'; // 万亿
  } else if (absNum >= 1e9) {
    return sign + (absNum / 1e9).toFixed(2) + 'B'; // 十亿
  } else if (absNum >= 1e6) {
    return sign + (absNum / 1e6).toFixed(2) + 'M'; // 百万
  } else if (absNum >= 1e3) {
    return sign + (absNum / 1e3).toFixed(2) + 'K'; // 千
  } else {
    return sign + absNum.toFixed(2).toString();
  }
}
