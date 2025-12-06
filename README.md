# **Mun Skill Swap - Group 7**

Mun Skill Swap is a Flutter-based mobile application designed to help users exchange skills, schedule sessions, and communicate seamlessly through real-time chat, video calls, and personalized recommendations. The app is built with a focus on smooth navigation, intuitive UI, and meaningful interactions.

---

## 🚀 **Features**

### **✨ Onboarding & Authentication**
- **Welcome Screen** introducing the platform.
- **MUN Authentication** for secure sign-in.
- **Login & Signup** with email/password.
- **Password Reset** functionality.
- **Profile Setup** during onboarding.

---

### **🧭 Navigation**
- Fully implemented navigation flow between all app screens.
- Consistent UX across authentication, feed, profiles, and chat.

---

### **🏠 Feed & Discovery**
- **Feed Screen** showing posts from the skill-swap community.
- **Advanced Filters** and **Search Bar** to find relevant content.
- **Smart Recommendations** based on user skills and interest.
- **Create Posts** for both feed posts and skill swap requests.
- **Saved Posts** for easy access and revisit later.

---

### **📅 Sessions & Scheduling**
- Users can **schedule sessions** with others.
- Dedicated screen for:
  - **Upcoming Sessions**
  - **Completed Sessions**

---

### **🌗 Light & Dark Mode**
- Built-in **theme toggle** supporting light and dark modes across the entire UI.

---

### **👤 Profile Management**
- **Profile View & Edit** screens.
- Organized **Skill Categories** for user expertise.
- **Public Profile Page** showing:
  - User info  
  - Skills  
  - Reviews  
  - Availability  
- From public profiles, users can:
  - Start a chat  
  - Request a swap  
  - Schedule a session  

---

### **🔔 Notifications**
- **Notification Screen** displaying:
  - New messages  
  - Review reminders  
  - Scheduled session alerts  
- **Push Notifications** with Firebase Cloud Messaging.

---

### **💬 Real-Time Chat (Firestore)**
Fully integrated Firestore chat with:
- Real-time sending & receiving messages  
- Read statuses  
- Message deletion  
- Chat deletion  
- Swap status updates inside chat  
- **Mark Swap as Done** + leave review flow  
- Review saved to user profile and other user notified accordingly  

---

### **📞 Video Calling (ZegoCloud)**
- Integrated **Zego** video calling SDK.
- Chat video icon automatically:
  - Creates a new call session, or  
  - Reuses an existing one  
- Opens the full Zego call UI.

---

## 🛠 **Tech Stack**
- **Flutter / Dart**
- **Firebase Auth**
- **Firestore**
- **Firebase Cloud Messaging (FCM)**
- **ZegoCloud Video SDK**
- **Provider / Riverpod / Bloc** (depending on your state management choice)