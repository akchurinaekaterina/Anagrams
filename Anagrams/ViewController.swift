//
//  ViewController.swift
//  Anagrams
//
//  Created by Ekaterina Akchurina on 23/09/2020.
//

import UIKit

class ViewController: UITableViewController {
    
    var allWordds = [String]()
    var usedWords = [String]()
    
    var currentWord = ""
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(typeWord))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(restartGame))
        
        if let startWordURL = Bundle.main.url(forResource: "start", withExtension: ".txt") {
            if let startWords = try? String(contentsOf: startWordURL) {
                allWordds = startWords.components(separatedBy: "\n")
            }
        }
        
        
        if allWordds.isEmpty {
            allWordds = ["abyrvalg"]
        }
        
        startGame()
        // Do any additional setup after loading the view.
    }
    
    @objc func startGame(){
        let defaults = UserDefaults.standard
        
        let decoder = JSONDecoder()
        if let encodedTitle = defaults.object(forKey: "mainWord") as? Data, let encodedGuess = defaults.object(forKey: "usedWord") as? Data{
            if let oldTitle = try? decoder.decode(String.self, from: encodedTitle) {
                title = oldTitle
                
                if let oldGuesses = try? decoder.decode([String].self, from: encodedGuess) {
                    usedWords = oldGuesses
                } else {
                    usedWords = ["no words entered"]
                }
            }
        } else {
            title = allWordds.randomElement()
            saveTitle()
        }
        
        
        
        tableView.reloadData()
    }
    @objc func restartGame(){
        title = allWordds.randomElement()
        saveTitle()
        usedWords.removeAll(keepingCapacity: true)
        saveUsedWords()
        tableView.reloadData()
    }
    func saveTitle(){
        let defaults = UserDefaults.standard
        let encoder = JSONEncoder()
        guard let encodedWord = try? encoder.encode(title) else {return}
        defaults.set(encodedWord, forKey: "mainWord")
    }
    func saveUsedWords(){
        let defaults = UserDefaults.standard
        let encoder = JSONEncoder()
        guard let encodedGuess = try? encoder.encode(usedWords) else {return
            print("unable to save")
        }
        defaults.set(encodedGuess, forKey: "usedWord")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    @objc func typeWord(){
        let newWord = UIAlertController(title: "Type your answer", message: nil, preferredStyle: .alert)
        newWord.addTextField()
        let submit = UIAlertAction(title: "Submit", style: .default) { [weak self, weak newWord] action in
            guard let answer = newWord?.textFields?[0].text else {return}
            self?.submit(answer)
        }
        newWord.addAction(submit)
        present(newWord, animated: true, completion: nil)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        if isPossible(lowerAnswer) {
            if isReal(lowerAnswer) {
                if isOriginal(lowerAnswer) {
                    usedWords.insert(lowerAnswer, at: 0)
                    saveUsedWords()
                    DispatchQueue.main.async {
                        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    }
                }
                else {
                    showMistake(title: "This word has been already used", text: "try again")
                }
            }
            else {
                showMistake(title: "This word does not exist or is too short", text: "try again")
            }
        } else {
            showMistake(title: "This word is not possible", text: "try again")
        }
        

    }
    
    func isPossible (_ word: String) -> Bool {
        guard var tempWord = title?.lowercased() else {return false}
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }
    func isOriginal (_ word: String) -> Bool {
        if word == title?.lowercased() {
            return false
        }
        return !usedWords.contains(word)
    }
    
    func isReal (_ word: String) -> Bool {
        if word.count < 3 {
            return false
        }
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
    
    func showMistake(title: String, text: String) {
        let mistakeAlert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        mistakeAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(mistakeAlert, animated: true, completion: nil)
    }


}

