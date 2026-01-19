import { StatusBar } from 'expo-status-bar';
import { Text, View } from 'react-native';
import "./global.css";

export default function App() {
  return (
    // Thử nghiệm class NativeWind: bg-slate-100 (màu nền), flex-1 (chiếm hết màn hình)
    <View className="flex-1 items-center justify-center bg-slate-100">
      
      <View className="p-6 bg-white rounded-2xl shadow-lg border border-slate-200">
        <Text className="text-xl font-bold text-blue-600 text-center">
          Trippie App 🚀
        </Text>
        <Text className="mt-2 text-slate-500 text-center">
          Nếu bạn thấy chữ màu xanh và nền xám,
          {"\n"}NativeWind đã chạy thành công!
        </Text>
      </View>

      <StatusBar style="auto" />
    </View>
  );
}