//
//  SurveyChatViewController.swift
//  BlahBlahBot
//
//  Created by Donghoon Shin on 2020/12/18.
//

import UIKit
import InputBarAccessoryView
import Firebase
import MessageKit
import FirebaseFirestore
import SDWebImage
import IQKeyboardManagerSwift

class SurveyChatViewController: MessagesViewController, InputBarAccessoryViewDelegate, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    var currentQuestionIndex = 0
    
    var displayName = "나"
    
    var botID = UUID().uuidString
    
    var isInitial = true
    
    private var docReference: DocumentReference?
    
    var messages: [Message] = []
    
    var lastDate = Date()
    
    var timer = Timer()
    
    @objc func updateCounting(){
        if currentQuestionIndex == 0 && Date().timeIntervalSince(lastDate) > 120.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.sendBotMessage(text: "그럼 지금부터 다음 질문으로 넘어가겠습니다. 상대방과 대화하면서 아쉬웠던 점은 무엇이었나요? (2분)")
            }
            lastDate = Date()
            currentQuestionIndex += 1
        }
        if currentQuestionIndex == 1 && Date().timeIntervalSince(lastDate) > 120.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.sendBotMessage(text: "응답을 완료해주셔서 감사합니다! 다음 화면에서 설문조사를 완료하면 실험이 종료됩니다. 설문조사까지 완료해야 실험비 지급이 완료되니, 참여자ID를 정확히 입력해주세요:)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SurveyWebViewController") as! SurveyWebViewController
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
            }
            currentQuestionIndex += 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
        
        navigationItem.hidesBackButton = true
        
        IQKeyboardManager.shared.enable = false
        
        self.title = "인터뷰"
        
        navigationItem.largeTitleDisplayMode = .never
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = .lightGray
        messageInputBar.inputTextView.autocorrectionType = .no
        messageInputBar.sendButton.setTitleColor(.darkGray, for: .normal)
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.inputTextView.placeholder = "메시지를 입력하세요"
        messageInputBar.sendButton.setTitle("전송", for: .normal)
        
        loadChat()
    }
    
    // MARK: - Custom messages handlers
    
    func typingIndicator(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        return TypingIndicatorCell()
    }
    
    func createNewChat() {
        let users = [experimentID, botID]
        let data: [String: Any] = [
            "users":users
        ]
        
        let db = Firestore.firestore().collection("Chats")
        db.addDocument(data: data) { (error) in
            if let error = error {
                print("Unable to create chat! \(error)")
                return
            } else {
                self.loadChat()
            }
        }
    }
    
    func loadChat() {
        
        //Fetch all the chats which has current user in it
        let db = Firestore.firestore().collection("Chats")
            .whereField("users", arrayContains: experimentID)
        
        
        db.getDocuments { (chatQuerySnap, error) in
            
            if let error = error {
                print("Error: \(error)")
                return
            } else {
                
                //Count the no. of documents returned
                guard let queryCount = chatQuerySnap?.documents.count else {
                    return
                }
                
                if queryCount == 0 {
                    //If documents count is zero that means there is no chat available and we need to create a new instance
                    self.createNewChat()
                }
                else if queryCount >= 1 {
                    //Chat(s) found for currentUser
                    for doc in chatQuerySnap!.documents {
                        
                        let chat = Chat(dictionary: doc.data())
                        //Get the chat which has user2 id
                        if (chat?.users.contains(self.botID))! {
                            
                            self.docReference = doc.reference
                            //fetch it's thread collection
                            doc.reference.collection("thread")
                                .order(by: "created", descending: false)
                                .addSnapshotListener(includeMetadataChanges: true, listener: { (threadQuery, error) in
                                    if let error = error {
                                        print("Error: \(error)")
                                        return
                                    } else {
                                        self.messages.removeAll()
                                        for message in threadQuery!.documents {
                                            
                                            let msg = Message(dictionary: message.data())
                                            self.messages.append(msg!)
                                            print("Data: \(msg?.content ?? "No message found")")
                                        }
                                        self.messagesCollectionView.reloadData()
                                        self.messagesCollectionView.scrollToBottom(animated: true)
                                        
                                        // handle bot here
                                        self.bot()
                                    }
                                })
                            return
                        } //end of if
                    } //end of for
                    self.createNewChat()
                } else {
                    print("Let's hope this error never prints!")
                }
            }
        }
    }
    
    
    private func insertNewMessage(_ message: Message) {
        
        lastDate = Date()
        
        messages.append(message)
        messagesCollectionView.reloadData()
        
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToBottom(animated: true)
        }
    }
    
    private func save(_ message: Message) {
        
        let data: [String: Any] = [
            "content": message.content,
            "created": message.created,
            "id": message.id,
            "senderID": message.senderID,
            "senderName": message.senderName
        ]
        
        docReference?.collection("thread").addDocument(data: data, completion: { (error) in
            
            if let error = error {
                print("Error Sending message: \(error)")
                return
            }
            
            self.messagesCollectionView.scrollToBottom()
            
        })
    }
    
    // MARK: - InputBarAccessoryViewDelegate
    
    func sendBotMessage(text: String) {
        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: botID, senderName: "봇")
        
        insertNewMessage(message)
        save(message)
        
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    func bot() {
        if isInitial {
            isInitial = false
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                self.sendBotMessage(text: "실험에 성실히 참여해주셔서 감사합니다. 지금부터는 상대방 없이 사용자와 봇 사이에서만 대화가 진행됩니다.")
                DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
                    self.sendBotMessage(text: "지금부터 총 4분간 두가지 주제에 대해 간단한 인터뷰를 진행하려고 하는데요, 각 질문의 시간이 끝나면 봇이 채팅으로 알려드립니다! 그 동안, 자유롭게 톡으로 질문에 대한 응답을 해주시면 됩니다.")
                    DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
                        self.sendBotMessage(text: "먼저, 상대방과 대화하면서 좋았던 점을 얘기해주세요:) (2분)")
                    }
                }
            }
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let message = Message(id: UUID().uuidString, content: text, created: Timestamp(), senderID: experimentID, senderName: self.displayName)
        
        //messages.append(message)
        insertNewMessage(message)
        save(message)
        
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    
    // MARK: - MessagesDataSource
    func currentSender() -> SenderType {
        
        return Sender(id: experimentID, displayName: displayName)
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
        
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        
        if messages.count == 0 {
            print("No messages to display")
            return 0
        } else {
            return messages.count
        }
    }
    
    
    // MARK: - MessagesLayoutDelegate
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
    
    // MARK: - MessagesDisplayDelegate
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        switch message.sender.senderId {
        case experimentID: return .systemBlue
        default: return .systemGreen
        }
    }
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        switch message.sender.senderId {
        case experimentID: return .white
        default: return .white
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        switch message.sender.senderId {
        case experimentID: avatarView.initials = "나"
        default: avatarView.initials = "봇"
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .curved)
        
    }
    
}
