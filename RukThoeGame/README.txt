วิธีใช้ (ไม่ต้องเปิดผ่าน claude.ai)

A) ตั้งฐานข้อมูล Firebase (ฟรี ทำครั้งเดียว ~5 นาที)
1) เข้า console.firebase.google.com > Add project (ตั้งชื่ออะไรก็ได้)
2) เมนู Build > Firestore Database > Create database > เลือก Start in test mode
   (หรือในแท็บ Rules ใส่:  allow read, write: if true;  แล้ว Publish)
3) ไอคอนเฟือง > Project settings > Your apps > กดไอคอน </> (Web) > ลงทะเบียนแอป
4) copy ค่า apiKey และ projectId มาใส่ใน index.html บรรทัด
   const FB = { projectId: "", apiKey: "" };

B) อัปโหลดทั้งโฟลเดอร์ขึ้นเว็บ https เช่น netlify.com/drop แล้วเปิดลิงก์ได้เลย
   (มือถือ: เมนูเบราว์เซอร์ > เพิ่มลงหน้าจอหลัก)

บัญชีแอดมิน Admin9585 จะถูกสร้างให้อัตโนมัติเมื่อเปิดครั้งแรก
โหมด AI ยังต้องใส่ API Key ของ AI ที่เลือกเอง
