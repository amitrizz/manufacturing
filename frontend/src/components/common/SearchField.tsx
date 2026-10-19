import { Ionicons } from '@expo/vector-icons';
import { useEffect, useState } from 'react';
import { Pressable, StyleSheet, TextInput, View } from 'react-native';
import { colors } from '../../theme';

type Props = {
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  debounceMs?: number;
};

export function SearchField({
  value,
  onChangeText,
  placeholder = 'Search…',
  debounceMs = 300,
}: Props) {
  const [local, setLocal] = useState(value);
  const [isFocused, setIsFocused] = useState(false);

  useEffect(() => {
    setLocal(value);
  }, [value]);

  useEffect(() => {
    const t = setTimeout(() => onChangeText(local), debounceMs);
    return () => clearTimeout(t);
  }, [local, debounceMs, onChangeText]);

  const handleClear = () => {
    setLocal('');
    onChangeText('');
  };

  return (
    <View style={[styles.container, isFocused && styles.containerFocused]}>
      <Ionicons
        name="search"
        size={18}
        color={isFocused ? colors.primary : colors.textMuted}
        style={styles.searchIcon}
      />
      <TextInput
        style={styles.input}
        value={local}
        onChangeText={setLocal}
        onFocus={() => setIsFocused(true)}
        onBlur={() => setIsFocused(false)}
        placeholder={placeholder}
        placeholderTextColor={colors.textMuted}
        autoCapitalize="none"
        autoCorrect={false}
      />
      {local.length > 0 && (
        <Pressable onPress={handleClear} hitSlop={8} style={styles.clearBtn}>
          <Ionicons name="close-circle" size={17} color={colors.textMuted} />
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 12,
    paddingHorizontal: 12,
    height: 44,
  },
  containerFocused: {
    borderColor: colors.primary,
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.12,
    shadowRadius: 3,
    elevation: 2,
  },
  searchIcon: {
    marginRight: 8,
  },
  input: {
    flex: 1,
    color: colors.text,
    fontSize: 14,
    paddingVertical: 0,
  },
  clearBtn: {
    padding: 2,
    marginLeft: 4,
  },
});

