import * as DocumentPicker from "expo-document-picker";
import { useEffect, useState } from "react";
import {
  Button,
  SafeAreaView,
  ScrollView,
  Text,
  View,
  Alert,
} from "react-native";
import PDFToolkit from "expo-pdf-toolkit";

export default function App() {
  const [fileLabel, setFileLabel] = useState<string>("");
  const [tempFileUri, setTempFileUri] = useState<string>("");
  const [status, setStatus] = useState<string>("");
  const [thumbnailPath, setThumbnailPath] = useState<string>("");
  const [isLoading, setIsLoading] = useState<boolean>(false);

  useEffect(() => {
    PDFToolkit.addListener("onProgress", ({ progress, page, total }) => {
      console.log(
        `진행률: ${Math.round(progress * 100)}%, 페이지: ${page}/${total}`
      );
    });

    return () => {
      // 컴포넌트 언마운트 시 리스너 제거
      PDFToolkit.removeAllListeners("onProgress");
    };
  }, []);

  // 안전한 PDF 로딩 함수
  const loadPdf = async (
    uri: string,
    pageNumber: number = 0
  ): Promise<string> => {
    console.log(`[loadPdf] uri: ${uri}, pageNumber: ${pageNumber} 시작`);

    return new Promise((resolve, reject) => {
      console.log("[loadPdf] Promise 생성됨");

      try {
        console.log("[loadPdf] PDFToolkit.getPageThumbnail 호출 직전");

        // 타임아웃 설정
        const timeoutId = setTimeout(() => {
          console.log("[loadPdf] 타임아웃 발생 (10초)");
          reject(new Error("PDF 로딩 타임아웃 (10초)"));
        }, 10000);

        PDFToolkit.getPageThumbnail(uri, pageNumber, {
          scale: 1.0,
          compressionQuality: 0.7,
        })
          .then((result) => {
            console.log(`[loadPdf] 성공: ${result}`);
            clearTimeout(timeoutId);
            resolve(result);
          })
          .catch((error) => {
            console.log(`[loadPdf] 오류: ${error}`);
            clearTimeout(timeoutId);
            reject(error);
          });

        console.log(
          "[loadPdf] PDFToolkit.getPageThumbnail 호출 직후 (비동기 실행 중)"
        );
      } catch (error) {
        console.log(`[loadPdf] 예외 발생: ${error}`);
        reject(error);
      }
    });
  };

  const handleDocumentPicker = async () => {
    try {
      setIsLoading(true);
      setStatus("문서 선택기 시작...");
      const result = await DocumentPicker.getDocumentAsync({
        type: "application/pdf",
        copyToCacheDirectory: true,
      });

      if (result.canceled) {
        setStatus("사용자가 문서 선택을 취소함");
        setIsLoading(false);
        return;
      }

      const { uri, name } = result.assets[0];
      setFileLabel(name);
      setTempFileUri(uri);
      setStatus(`PDF 파일 선택됨: ${name}`);
      console.log(`문서 URI: ${uri}`);

      // 파일 경로 검증 (안드로이드에서는 content:// URI 사용할 수 있음)
      try {
        setStatus("파일명 검증 중...");
        const fileName = await PDFToolkit.getFileName(uri);
        setStatus(`파일명 검증 성공: ${fileName}`);
        console.log(`파일명: ${fileName}`);
      } catch (fileNameError) {
        console.error("파일명 검증 실패:", fileNameError);
        setStatus(`파일명 검증 실패: ${fileNameError}`);
        Alert.alert("오류", `파일명 검증 실패: ${fileNameError}`);
        setIsLoading(false);
        return;
      }

      try {
        // 특정 페이지 변환 시도
        setStatus("특정 페이지만 변환 시도 중... (페이지 0)");
        console.log("PDF 변환 시작");

        // 페이지 번호를 항상 0으로 고정 (첫 페이지)
        const pageNumber = 0;

        // 직접 호출 방식으로 변경
        console.log(
          `PDFToolkit.getPageThumbnail 직접 호출: ${uri}, 페이지 ${pageNumber}`
        );
        const thumbnail = await PDFToolkit.getPageThumbnail(uri, pageNumber, {
          scale: 1.0,
          compressionQuality: 0.7,
        });

        console.log(`썸네일 생성 성공: ${thumbnail}`);
        setThumbnailPath(thumbnail);
        setStatus(`썸네일 생성 성공: ${thumbnail}`);
        Alert.alert("성공", "썸네일이 생성되었습니다.");
      } catch (thumbnailError) {
        console.error("썸네일 생성 오류:", thumbnailError);
        setStatus(`썸네일 생성 실패: ${JSON.stringify(thumbnailError)}`);
        Alert.alert("오류", `썸네일 생성 실패: ${thumbnailError}`);
      } finally {
        setIsLoading(false);
      }
    } catch (error) {
      console.error("문서 선택 오류:", error);
      setStatus(`문서 선택 오류: ${error}`);
      Alert.alert("오류", `문서 선택 오류: ${error}`);
      setIsLoading(false);
    }
  };

  const handleConvertAll = async () => {
    if (!tempFileUri) {
      setStatus("먼저 PDF 파일을 선택해주세요.");
      Alert.alert("안내", "먼저 PDF 파일을 선택해주세요.");
      return;
    }

    try {
      setIsLoading(true);
      setStatus("모든 페이지 변환 시도 중...");
      const images = await PDFToolkit.convertToImages(tempFileUri, {
        scale: 0.5,
        compressionQuality: 0.5,
      });
      setStatus(`변환 성공: ${images.length}개 이미지 생성`);
      Alert.alert("성공", `${images.length}개의 이미지가 생성되었습니다.`);
    } catch (convertError) {
      console.error("전체 변환 오류:", convertError);
      setStatus(`전체 변환 실패: ${JSON.stringify(convertError)}`);
      Alert.alert("오류", `전체 변환 실패: ${convertError}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>PDF 툴킷 예제</Text>
        <Group name="상태">
          <Text>{status}</Text>
          {thumbnailPath ? <Text>썸네일: {thumbnailPath}</Text> : null}
          {isLoading ? <Text style={{ color: "blue" }}>로딩 중...</Text> : null}
        </Group>
        <Group name="PDF 처리">
          <Button
            title="PDF 업로드"
            onPress={handleDocumentPicker}
            disabled={isLoading}
          />
          <View style={{ height: 10 }} />
          <Button
            title="모든 페이지 변환"
            onPress={handleConvertAll}
            disabled={!tempFileUri || isLoading}
          />
        </Group>
        <Group name="선택된 파일">
          <Text>{fileLabel || "선택된 파일 없음"}</Text>
          {tempFileUri ? (
            <Text style={{ fontSize: 12 }}>{tempFileUri}</Text>
          ) : null}
        </Group>
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: {
    fontSize: 30,
    margin: 20,
  },
  groupHeader: {
    fontSize: 20,
    marginBottom: 20,
  },
  group: {
    margin: 20,
    backgroundColor: "#fff",
    borderRadius: 10,
    padding: 20,
  },
  container: {
    flex: 1,
    backgroundColor: "#eee",
  },
  view: {
    flex: 1,
    height: 200,
  },
};
