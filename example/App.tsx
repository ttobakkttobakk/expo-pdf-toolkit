import { useEvent } from "expo";
import * as DocumentPicker from "expo-document-picker";
import { useState } from "react";
import { Button, SafeAreaView, ScrollView, Text, View } from "react-native";
import PDFToolkit from "react-native-pdf-toolkit";

export default function App() {
  // const onChangePayload = useEvent(PDFToolkit, "onChange");
  const [fileLabel, setFileLabel] = useState<string>("");
  const [tempFileUri, setTempFileUri] = useState<string>("");

  const handleDocumentPicker = async () => {
    const result = await DocumentPicker.getDocumentAsync({
      type: "application/pdf",
      copyToCacheDirectory: true,
    });

    if (result.canceled) return;

    const { uri, name } = result.assets[0];

    setFileLabel(name);
    setTempFileUri(uri);

    console.log(PDFToolkit.convertToImages);

    const realPath = uri.replace("file://", "");
    const images = await PDFToolkit.convertToImages(realPath);

    console.log(images);
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Module API Example</Text>
        {/* <Group name="Constants">
          <Text>{PDFToolkit.PI}</Text>
        </Group>
        <Group name="Functions">
          <Text>{PDFToolkit.hello()}</Text>
        </Group> */}
        <Group name="Async functions">
          <Button title="PDF 업로드" onPress={handleDocumentPicker} />
        </Group>
        <Group name="Events">
          <Text>{fileLabel}</Text>
        </Group>
        {/* <Group name="Views">
          <PDFToolkitView
            url="https://www.example.com"
            onLoad={({ nativeEvent: { url } }) => console.log(`Loaded: ${url}`)}
            style={styles.view}
          />
        </Group> */}
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
