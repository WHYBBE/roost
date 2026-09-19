/// 热力图色阶阈值
const moodLevels = [0, 1, 2, 3, 4, 6, 9];

int heatLevel(int count) {
  for (var i = moodLevels.length - 1; i >= 0; i--) {
    if (count >= moodLevels[i]) return i;
  }
  return 0;
}
