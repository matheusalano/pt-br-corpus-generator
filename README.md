# pt-br-corpus-generator

This application is a part of my degree's final project, which was a bilingual chatbot using Deep Learning techniques.

The goal of this application was at first to translate to Brazilian Portuguese a dataset with the utterances of the TV Series Friends.

First, I tried to find each Portuguese utterance by (i) finding the English subtitle for each utterance of the dataset using Levenstein's algorithm. Then, (ii) I tried to find the Portuguese subtitle based on the subtitle's timestamp. 

However, I found some problems like N subtitles for only one utterance and different subtitle's timestamps for English and Portuguese. I couldn't find all the utterances in Portuguese using this technique, so the remaining ones were translated using the Google Translate API. 

The final dataset containing the English and Portuguese utterance isn't 100% yet. There are some tags (e.g. REVIEW or ONLY_TRANS) to specify utterances that require manual review or that were translated by the API. A simple pre-processing should clean the dataset, though.

The Cornell's Movie-Dialogs was also translated to Portuguese. This time, I used the API for the entire process. Since this dataset is more formal than the former one, there are fewer mistakes. So it's probably ready for use.
